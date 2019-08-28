// Provider VARs
variable "access_key" {}

variable "secret_key" {}

variable "region" {
  default = "us-east-1"
}

// Nomad EC2 Instances VARs
variable "nomad_instance_count" {
  default = "3"
}

variable "instance_role" {
  description = "Nomad instance type"
  default     = "server"
}

variable "public_key" {}

variable "aws_vpc_id" {}

variable "subnet_id" {}

variable "instance_type" {
  default = "t2.micro"
}

variable "ami" {
  description = "Ubuntu Xenial Nomad Server AMI in AWS us-east-1 region"
  default     = "ami-0ac8c1373dae0f3e5"
}

variable "sg_ids" {
   type    = list
}

variable "role_name" {
  description = "Name for IAM role that allows Nomad cloud auto join"
  default     = "nomad-cloud-auto-join-aws"
}

variable "dc" {
  type        = string
  default     = "dc1"
  description = "Define the name of Nomad datacenter"
}

variable "nomad_region" {
  type        = string
  default     = "global"
  description = "Define the name of Nomad region"
}

variable "authoritative_region" {
  type        = string
  default     = "global"
  description = "Define the name of Nomad authoritative region"
}

variable "retry_join" {
  description = "Used by Nomad to automatically form a cluster"
  default     = "provider=aws tag_key=nomad-node tag_value=server"
}

variable "secure_gossip" {
  description = "Used by Nomad to enable gossip encryption"
  default     = "null"
}

// Cloudflare VARs
variable "zone_name" {
  description = "The name of DNS domain"
  default = "ntry.site"
}

variable "domain_name" {
  description = "The name of subdomain"
  default = "mynomad"
}
