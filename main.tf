// Generates Random Name for Instances
resource "random_pet" "random_name" {
  length    = "4"
  separator = "-"
}

// Generates AWS Key Pairs for Instances
resource "aws_key_pair" "my_key" {
  key_name   = "key-${random_pet.random_name.id}"
  public_key = file("~/.ssh/id_rsa.pub")
}

// Generates an IAM policy document in JSON format
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

// Creates an IAM Role and Instance Profile with a necessary permission required for Nomad Cloud-Join
resource "aws_iam_role" "nomad" {
  name               = "${var.nomad_region}-${var.dc}-nomad-cloud-auto-join-aws"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "nomad" {
  statement {
    sid       = "AllowSelfAssembly"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ec2:DescribeInstances",
    ]
  }
}

// Generates an IAM policy document in JSON format
resource "aws_iam_role_policy" "nomad" {
  name   = "${var.nomad_region}-${var.dc}-nomad-cloud-auto-join-aws"
  role   = aws_iam_role.nomad.id
  policy = data.aws_iam_policy_document.nomad.json
}

// Provides an IAM instance profile
resource "aws_iam_instance_profile" "nomad" {
  name = "${var.nomad_region}-${var.dc}-nomad-cloud-auto-join-aws"
  role = aws_iam_role.nomad.name
}

// Create security group to allow Nomad traffic
resource "aws_security_group" "nomad" {
  name        = "nomad"
  description = "Ingress for Nomad"
  vpc_id      = var.aws_vpc_id

  dynamic "ingress" {
    iterator = port
    for_each = var.ingress_tcp_ports_nomad
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  dynamic "ingress" {
    iterator = port
    for_each = var.ingress_udp_ports_nomad
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "udp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  // Custom ICMP Rule - IPv4 Echo Reply
  ingress {
    from_port   = "0"
    to_port     = "-1"
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // Custom ICMP Rule - IPv4 Echo Request
  ingress {
    from_port   = "8"
    to_port     = "-1"
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allowed_nomad_traffic"
  }
}

// Creates AWS EC2 instances for nomad server
resource "aws_instance" "nomad_server" {
  count                       = var.nomad_server_count
  ami                         = var.ami_nomad_server
  instance_type               = var.instance_type_server
  subnet_id                   = var.server_subnet_id
  vpc_security_group_ids      = [aws_security_group.nomad.id]
  iam_instance_profile        = aws_iam_instance_profile.nomad.id
  key_name                    = aws_key_pair.my_key.id
  associate_public_ip_address = var.private_subnet_with_nat_gw == "true" ? "false" : "true"

  tags = {
    Name       = "${var.nomad_region}-${var.dc}-${random_pet.random_name.id}-server-0${count.index + 1}"
    nomad-node = "server"
  }

  user_data = templatefile("${path.module}/templates/nomad-config.tpl", { instance_role = "server", nomad_region = var.nomad_region, dc = var.dc, authoritative_region = var.authoritative_region, retry_join = var.retry_join, secure_gossip = var.secure_gossip, domain_name = var.subdomain_name, zone_name = var.cloudflare_zone })
}

// Creates AWS EC2 instances for nomad client
resource "aws_instance" "nomad_client" {
  count                       = var.nomad_client_count
  ami                         = var.ami_nomad_client
  instance_type               = var.instance_type_client
  subnet_id                   = var.client_subnet_id
  vpc_security_group_ids      = [aws_security_group.nomad.id]
  iam_instance_profile        = aws_iam_instance_profile.nomad.id
  key_name                    = aws_key_pair.my_key.id
  associate_public_ip_address = var.private_subnet_with_nat_gw == "true" ? "false" : "true"

  tags = {
    Name       = "${var.nomad_region}-${var.dc}-${random_pet.random_name.id}-client-0${count.index + 1}"
    nomad-node = "client"
  }

  user_data = templatefile("${path.module}/templates/nomad-config.tpl", { instance_role = "client", nomad_region = var.nomad_region, dc = var.dc, authoritative_region = var.authoritative_region, retry_join = var.retry_join, secure_gossip = var.secure_gossip, domain_name = var.subdomain_name, zone_name = var.cloudflare_zone })
}

// Frontend config

// Set local vars
locals {
  # Nomad servers IP:port sockets
  nomad_servers_socket = join(" ", formatlist("%s %s:%s;", "server", aws_instance.nomad_server.*.private_ip, "4646"))
}

# // Create security group to allow Frontend traffic
resource "aws_security_group" "frontend" {
  count       = var.ui_enabled == "true" ? 1 : 0
  name        = "frontend"
  description = "Ingress for nomad frontend"
  vpc_id      = var.aws_vpc_id

  dynamic "ingress" {
    iterator = port
    for_each = var.ingress_tcp_ports_frontend
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  // all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allowed_frontend_traffic"
  }
}

// Creates AWS EC2 instance for nomad frontend server if UI is enabled
resource "aws_instance" "frontend" {
  count                       = var.ui_enabled == "true" ? 1 : 0
  ami                         = var.ami_frontend
  instance_type               = var.instance_type_frontend
  subnet_id                   = var.frontend_subnet_id
  vpc_security_group_ids      = [aws_security_group.frontend[0].id]
  key_name                    = aws_key_pair.my_key.id
  associate_public_ip_address = "true"

  tags = {
    Name = "${var.nomad_region}-${var.dc}-${random_pet.random_name.id}-frontend"
  }

  user_data = templatefile("${path.module}/templates/nginx-config.tpl", { nomad_region = var.nomad_region })
}

// This makes the nginx configuration 
resource "null_resource" "nginx_config" {
  count = var.ui_enabled == "true" ? 1 : 0

  # changes to any server instance of the nomad cluster requires re-provisioning
  triggers = {
    nginx_upstream_nodes   = local.nomad_servers_socket
    cloudflare_record_ip   = cloudflare_record.nomad_frontend[0].value
    cloudflare_record_name = cloudflare_record.nomad_frontend[0].name
  }

  depends_on = [
    aws_instance.frontend,
    aws_instance.nomad_server
  ]

  # script can run on every nomad server instance change
  connection {
    type        = "ssh"
    host        = aws_instance.frontend[0].public_ip
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    # script called with private_ips of nomad backend servers
    inline = [
      "sleep 5",
      "sudo /root/nginx-upstream-config.sh '${local.nomad_servers_socket}'",
      "sudo systemctl restart nginx.service"
    ]
  }
}

// Creates a DNS record with Cloudflare
resource "cloudflare_record" "nomad_frontend" {
  count  = var.ui_enabled == "true" ? 1 : 0
  domain = var.cloudflare_zone
  name   = var.subdomain_name
  value  = aws_instance.frontend[0].public_ip
  type   = "A"
  ttl    = 3600
}

# Generates a trusted certificate issued by Let's Encrypt
resource "null_resource" "certbot" {
  count = var.ui_enabled == "true" ? 1 : 0
  # Changes to any instance of the cluster requires re-provisioning
  triggers = {
    cloudflare_record = cloudflare_record.nomad_frontend[0].value
  }

  depends_on = [
    cloudflare_record.nomad_frontend,
    null_resource.nginx_config[0],
  ]

  # certbot script can run on every instance ip change
  connection {
    type        = "ssh"
    host        = aws_instance.frontend[0].public_ip
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    # certbot script called with public_ip of frontend server
    inline = [
      "sudo certbot --nginx --non-interactive --agree-tos -m ${var.cloudflare_email} -d ${var.subdomain_name}.${var.cloudflare_zone} --redirect",
    ]
  }
}

