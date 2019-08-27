# Terraform module to create Nomad (clients|servers) instances on AWS

## Prerequisites

- git
- terraform (>=0.12)
- AWS subscription
- ssh key
- Use pre-built nomad server and/or client AWS AMIs or bake your own using [Packer](https://www.packer.io)
- VPN connection with AWS to access AWS EC2 instances on their private IPs
- cfssl (Cloudflare's PKI and TLS toolkit)

## Consume

- Create `terraform.tfvars` file

### Inputs

| Name  |	Description |	Type |  Default |	Required
| ----- | ----------- | ---- |  ------- | --------
| access_key | Requester AWS access key | string | - | yes
| secret_key | Requester AWS secret key | string | - | yes
| region | Requester AWS region | string | "us-east-1" | no
| nomad_instance_count | Nomad instance count | number | "3" | no
| instance_type | EC2 instance type | string | "t2.micro" | no
| aws_vpc_id | AWS VPC id | string | - | yes
| subnet_id | AWS VPC subnet id | string | - | yes
| availability_zone | AZ id of the AWS VPC subnet | string | - | yes
| sg_ids | List of AWS Security groups | list | - | yes
| ami | Nomad server or client AWS AMI | string | "ami-0ac8c1373dae0f3e5" | no
| public_key | A public key used by AWS to generates key pairs for instances | string | - | yes
| role_name | Name for IAM role that allows Nomad cloud auto join | string | "nomad-cloud-auto-join-aws" | no
| instance_role | Nomad instance role type (client/server) | string | "server" | no
| dc | Define the name of Nomad datacenter | string | "dc1" | no
| nomad_region | Define the name of Nomad region | string | "global" | no
| authoritative_region | Define the name of Nomad authoritative region | string | "global" | no
| retry_join | Used by Nomad to automatically form a cluster | string | "provider=aws tag_key=nomad-node tag_value=server" | no
| secure_gossip | Used on Nomad server instances only to enable gossip encryption | string | "null" | yes
| domain_name | The name of subdomain | string | "mynomad" | no
| zone_name | The name of DNS domain | string | "ntry.site" | no



- Create `main.tf` file:

```
// Generate private Certificate Authority (CA) and issue certificates for Nomad nodes

resource "null_resource" "generate_self_ca" {
  provisioner "local-exec" {
    # script called with private_ips of nomad backend servers
    command = "${path.root}/.terraform/modules/aws-nomad_server/scripts/gen_self_ca.sh ${var.nomad_region}" 
  }
}

// Generate 16 bytes, base64 encoded cryptographically suitable key to enable gossip encryption on Nomad servers
resource "random_id" "server_gossip" {
  byte_length = 16
}

// Creates security groups that allow all ports needed for Nomad
resource "aws_security_group" "allow_nomad_traffic_sg" {
  name        = "allow_nomad_traffic_sg"
  description = "Allow traffic needed for Nomad"
  vpc_id      = var.aws_vpc_id

  // nomad
  ingress {
    from_port   = "4646"
    to_port     = "4648"
    protocol    = "tcp"
    cidr_blocks = ["${var.nomad_cidr}"]
  }

  ingress {
    from_port   = "4648"
    to_port     = "4648"
    protocol    = "udp"
    cidr_blocks = ["${var.nomad_cidr}"]
  }

  // all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_nomad_traffic"
  }
}

resource "aws_security_group" "allow_nomad_icmp_traffic" {
  name        = "allow_nomad_icmp_traffic_sg"
  description = "Allow traffic needed for Nomad"
  vpc_id      = var.aws_vpc_id

  // Custom ICMP Rule - IPv4 Echo Reply
  ingress {
    from_port   = "0"
    to_port     = "-1"
    protocol    = "icmp"
    cidr_blocks = ["${var.icmp_cidr}"]
  }

  // Custom ICMP Rule - IPv4 Echo Request
  ingress {
    from_port   = "8"
    to_port     = "-1"
    protocol    = "icmp"
    cidr_blocks = ["${var.icmp_cidr}"]
  }

  // all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_nomad_icmp_traffic"
  }
}

resource "aws_security_group" "allow_nomad_ssh_traffic" {
  name        = "allow_nomad_ssh_traffic_sg"
  description = "Allow traffic needed for Nomad"
  vpc_id      = var.aws_vpc_id

  // ssh
  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["${var.ssh_cidr}"]
  }

  // all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_nomad_ssh_traffic"
  }
}

// Module that creates Nomad server instances in AWS region "us-east-1", Nomad region "global" and Nomad "dc1"
module "aws-nomad_server" {
  source = "git@github.com:achuchulev/terraform-aws-nomad_instance.git"

  access_key           = "aws_access_key"
  secret_key           = "aws_secret_key"
  region               = "us-east-1"
  instance_role        = "server"
  nomad_instance_count = "3"
  aws_vpc_id           = "aws_vpc_id"
  availability_zone    = "aws_az_id"
  subnet_id            = "aws_subnet_id"
  sg_ids               = [aws_security_group.allow_nomad_traffic_sg.id,aws_security_group.allow_nomad_icmp_traffic.id,aws_security_group.allow_nomad_ssh_traffic.id]
  nomad_region         = "global"
  authoritative_region = "global"
  dc                   = "dc1"
  ami                  = "ami-0ac8c1373dae0f3e5" # Nomad server AWS AMI in us-east-1
  instance_type        = "t2.micro"
  public_key           = "a_public_key"
  domain_name          = "mynomad"
  zone_name            = "example.com"
  secure_gossip        = "cg8StVXbQJ0gPvMd9o7yrg=="
}

// Module that creates Nomad client instances in AWS region "us-east-1", Nomad region "global" and Nomad "dc1"
module "aws-nomad_client" {
  source = "git@github.com:achuchulev/terraform-aws-nomad_instance.git"

  access_key           = "aws_access_key"
  secret_key           = "aws_secret_key"
  region               = "us-east-1"
  instance_role        = "client"
  nomad_instance_count = "1"
  aws_vpc_id           = "aws_vpc_id"
  availability_zone    = "aws_az_id"
  subnet_id            = "aws_subnet_id"
  sg_ids               = [aws_security_group.allow_nomad_traffic_sg.id,aws_security_group.allow_nomad_icmp_traffic.id,aws_security_group.allow_nomad_ssh_traffic.id]
  nomad_region         = "global"
  dc                   = "dc1"
  ami                  = "ami-02ffa51d963317aaf" # Nomad client AWS AMI in us-east-1
  instance_type        = "t2.micro"
  public_key           = "a_public_key"
  domain_name          = "mynomad"
  zone_name            = "example.com"
}
```


- Initialize terraform

```
terraform init
```

- Deploy instances

```
terraform plan
terraform apply
```
- `Terraform apply` will:
  - generate private Certificate Authority (CA)
  - issue selfsigned certificates for Nomad nodes
  - generate 16 bytes, base64 encoded cryptographically suitable key for gossip encryption on Nomad servers
  - create new instances into the specified AWS region for server/client
  - copy nomad configuration files
  - bootstrap Nomad cluster
  
### Outputs

| Name  |	Description 
| ----- | ----------- 
| instance_tags  | Nomad instances tags
| nomad_ui_sockets | Nomad instances WEB UI sockets to provide to frontend
| private_ips  | Nomad instances private ips

## Access Nomad with CLI

- ssh to some Nomad node `ssh ubuntu@nomad_private_ip`

and 

- run for example:

```
$ nomad node status
$ nomad server members
```

