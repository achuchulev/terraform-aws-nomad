// Provider VARs
variable "access_key" {}

variable "secret_key" {}

variable "region" {
  default = "us-east-1"
}

// Number of Nomad server EC2 Instances
variable "nomad_server_count" {
  default = "3"
}

// Number of Nomad client EC2 Instance
variable "nomad_client_count" {
  default = "1"
}

variable "ui_enabled" {
  description = "Set to false to prevent the frontend from creating thus accessing Nomad UI"
  default     = "true"
}

variable "ssh_enabled" {
  description = "Set to false to prevent ssh"
  default     = "true"
}

variable "icmp_enabled" {
  description = "Set to false to prevent icmp ping"
  default     = "true"
}

variable "aws_vpc_id" {}

variable "subnet_id" {}

variable "instance_type_server" {
  default = "t2.micro"
}

variable "instance_type_client" {
  default = "t2.micro"
}

variable "instance_type_frontend" {
  default = "t2.micro"
}

variable "ami_nomad_server" {
  description = "Ubuntu Xenial Nomad Server AMI in AWS us-east-1 region"
  default     = "ami-0ac8c1373dae0f3e5"
}

variable "ami_nomad_client" {
  description = "Ubuntu Xenial Nomad Client AMI in AWS us-east-1 region"
  default     = "ami-02ffa51d963317aaf"
}

variable "ami_frontend" {
  description = "Ubuntu Xenial WEB Server AMI in AWS us-east-1 region"
  default     = "ami-090c16342ee6bb5cc"
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
variable "cloudflare_email" {
  description = "Used by Nomad frontend"
  default     = "null"
}

variable "cloudflare_token" {
  description = "Used by Nomad frontend"
  default     = "null"
}

variable "cloudflare_zone" {
  description = "Used by Nomad frontend"
  default     = "null"
}

variable "subdomain_name" {
  description = "Used by Nomad frontend"
  default     = "null"
}
