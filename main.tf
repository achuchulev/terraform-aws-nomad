// Generates Random Name for Instances
resource "random_pet" "random_name" {
  length    = "4"
  separator = "-"
}

// Generates AWS Key Pairs for Instances
resource "aws_key_pair" "my_key" {
  key_name   = "key-${random_pet.random_name.id}"
  public_key = var.public_key
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
  name               = "${var.nomad_region}-${var.dc}-${var.role_name}-${var.instance_role}"
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
  name   = "${var.nomad_region}-${var.dc}-${var.role_name}-${var.instance_role}"
  role   = aws_iam_role.nomad.id
  policy = data.aws_iam_policy_document.nomad.json
}

// Provides an IAM instance profile
resource "aws_iam_instance_profile" "nomad" {
  name = "${var.nomad_region}-${var.dc}-${var.role_name}-${var.instance_role}"
  role = aws_iam_role.nomad.name
}

// Creates AWS EC2 instances for nomad server/client
resource "aws_instance" "nomad_instance" {
  count                       = var.nomad_instance_count
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.sg_ids
  iam_instance_profile        = aws_iam_instance_profile.nomad.id
  key_name                    = aws_key_pair.my_key.id
  associate_public_ip_address = "false"

  tags = {
    Name       = "${var.nomad_region}-${var.dc}-${random_pet.random_name.id}-${var.instance_role}-0${count.index + 1}"
    nomad-node = var.instance_role
  }

  user_data = templatefile("${path.root}/templates/configuration.tmpl", { instance_role = var.instance_role, nomad_region = var.nomad_region, dc = var.dc, authoritative_region = var.authoritative_region, retry_join = var.retry_join, secure_gossip = var.secure_gossip, domain_name = var.domain_name, zone_name = var.zone_name })
}
