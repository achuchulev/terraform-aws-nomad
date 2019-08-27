# Terraform module to create Nomad (clients|servers) instances on AWS

## Inputs

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
| icmp_cidr | CIDR block to allow ICMP | string | - | no
| ssh_cidr | CIDR block to allow ssh | string | - | no
| nomad_cidr | CIDR block to allow nomad traffic | string | - | no
| ami | Nomad server or client AWS AMI | string | "ami-0ac8c1373dae0f3e5" | no
| public_key | A public key used by AWS to generates key pairs for instances | string | - | yes
| role_name | Name for IAM role that allows Nomad cloud auto join | string | "nomad-cloud-auto-join-aws" | no
| instance_role | Nomad instance role type (client/server) | string | "server" | no
| dc | Define the name of Nomad datacenter | string | "dc1" | no
| nomad_region | Define the name of Nomad region | string | "global" | no
| authoritative_region | Define the name of Nomad authoritative region | string | "global" | no
| retry_join | Used by Nomad to automatically form a cluster | string | "provider=aws tag_key=nomad-node tag_value=server" | no
| secure_gossip | Used by Nomad to enable gossip encryption | string | "cg8StVXbQJ0gPvMd9o7yrg==" | no
| domain_name | The name of subdomain | string | "mynomad" | no
| zone_name | The name of DNS domain | string | "ntry.site" | no


## Outputs

| Name  |	Description 
| ----- | ----------- 
| instance_tags  | Nomad instances tags
| nomad_ui_sockets | Nomad instances WEB UI sockets to provide to frontend
| private_ips  | Nomad instances private ips

## Consume

```
// ************* GLOBAL Part ************* //

resource "null_resource" "generate_self_ca" {
  provisioner "local-exec" {
    # script called with private_ips of nomad backend servers
    command = "${path.root}/scripts/gen_self_ca.sh ${var.nomad_region}"
  }
}

resource "random_id" "server_gossip" {
  byte_length = 16
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
  nomad_region         = "global"
  authoritative_region = "global"
  dc                   = "dc1"
  ami                  = "ami-0ac8c1373dae0f3e5"
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
  nomad_region         = "global"
  dc                   = "dc1"
  ami                  = "ami-02ffa51d963317aaf"
  instance_type        = "t2.micro"
  public_key           = "a_public_key"
  domain_name          = "mynomad"
  zone_name            = "example.com"
}
```
