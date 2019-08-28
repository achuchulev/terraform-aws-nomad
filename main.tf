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
  availability_zone           = var.availability_zone
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.sg_ids
  iam_instance_profile        = aws_iam_instance_profile.nomad.id
  key_name                    = aws_key_pair.my_key.id
  associate_public_ip_address = "false"

  tags = {
    Name       = "${var.nomad_region}-${var.dc}-${random_pet.random_name.id}-${var.instance_role}-0${count.index + 1}"
    nomad-node = var.instance_role
  }

  user_data = << EOF
		#!/usr/bin/env bash
    
    # create dir for nomad configuration
    sudo mkdir -p /etc/nomad.d
    sudo chmod 700 /etc/nomad.d

    # download and run nomad configuration script
    curl -o /tmp/nomad-${var.instance_role}-config.sh https://raw.githubusercontent.com/achuchulev/terraform-aws-nomad_instance/master/scripts/nomad-${var.instance_role}-config.sh
    chmod +x /tmp/nomad-${var.instance_role}-config.sh
    sudo /tmp/nomad-${var.instance_role}-config.sh ${var.nomad_region} ${var.dc} ${var.authoritative_region} '${var.retry_join}' ${var.secure_gossip}
    rm -rf /tmp/*

    # create dir for certificates and copy cfssl.json configuration file to increase the default certificate expiration time for nomad
    mkdir -p ~/nomad/ssl
    curl -o ~/nomad/ssl/cfssl.json https://github.com/achuchulev/terraform-aws-nomad_instance/blob/master/config/cfssl.json

    # download CA certificates
    curl -o ~/nomad/ssl/nomad-ca-key.pem https://raw.githubusercontent.com/achuchulev/terraform-aws-nomad_instance/master/ca_certs/nomad-ca-key.pem
    curl -o ~/nomad/ssl/nomad-ca.csr https://raw.githubusercontent.com/achuchulev/terraform-aws-nomad_instance/master/ca_certs/nomad-ca.csr
    curl -o ~/nomad/ssl/nomad-ca.pem https://raw.githubusercontent.com/achuchulev/terraform-aws-nomad_instance/master/ca_certs/nomad-ca.pem

    # generate nomad node certificates
    sudo echo '{}' | cfssl gencert -ca=nomad/ssl/nomad-ca.pem -ca-key=nomad/ssl/nomad-ca-key.pem -config=/tmp/cfssl.json -hostname='${var.instance_role}.${var.nomad_region}.nomad,localhost,127.0.0.1' - | cfssljson -bare nomad/ssl/${var.instance_role}

    # copy nomad.service
    sudo curl -o /etc/systemd/system/nomad.service https://raw.githubusercontent.com/achuchulev/terraform-aws-nomad_instance/master/config/nomad.service
    sudo echo '{}' | cfssl gencert -ca=nomad/ssl/nomad-ca.pem -ca-key=nomad/ssl/nomad-ca-key.pem -profile=client - | cfssljson -bare nomad/ssl/cli

    # Enable Nomad's CLI command autocomplete support. Skip if installed
    grep "complete -C /usr/bin/nomad nomad" ~/.bashrc &>/dev/null || nomad -autocomplete-install

    # enable and start nomad service
    sudo systemctl enable nomad.service
		sudo systemctl start nomad.service

    # export the URL of the Nomad agent
    echo 'export NOMAD_ADDR=https://${var.domain_name}.${var.zone_name}' >> ~/.profile
	EOF
}
