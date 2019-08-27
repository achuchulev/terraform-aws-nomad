# Terraform configuration to create nomad instances (clients|servers) on AWS

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
| nomad_ui_sockets | Nomad instances WEB UI sockets to provide to frontend
| instance_tags  | Nomad instances tags
| private_ips  | Nomad instances private ips
