# Terraform module to deploy Nomad cluster (clients and servers) on AWS with|without Frontend for UI. Kitchen test is included

## Prerequisites

- git
- terraform (>=0.12)
- AWS subscription
- ssh key
- Use pre-built nomad server and/or client AWS AMIs or bake your own using [Packer](https://www.packer.io)
- Claudflare subscription
- own domain managed by Claudflare
- A private subnet wit NAT_GW. If no such Nomad instances will get Public IP addresses
- selenium-server
- java jdk
- GeckoDriver | Chromedriver


## Consume

- Create `terraform.tfvars` file


```

access_key        = "your_aws_access_key"
secret_key        = "your_aws_secret_key"
aws_vpc_id        = "vpc_id"
subnet_id         = "subnet_id_"
secure_gossip     = "1/+0vQt75rYWJadtpEdEtg=="
cloudflare_email  = "me@example.com"
cloudflare_token  = "cloudflare_token"
cloudflare_zone   = "example.net"
subdomain_name    = "nomad-ui"
```

- Create `variables.tf` file

```
variable "access_key" {}
variable "secret_key" {}
variable "aws_vpc_id" {}
variable "subnet_id" {}
variable "secure_gossip" {}
variable "cloudflare_email" {}
variable "cloudflare_token" {}
variable "cloudflare_zone" {}
variable "subdomain_name" {}
```

#### Inputs

| Name  |	Description |	Type |  Default |	Required
| ----- | ----------- | ---- |  ------- | --------
| access_key | Requester AWS access key | string | - | yes
| secret_key | Requester AWS secret key | string | - | yes
| region | Requester AWS region | string | "us-east-1" | no
| nomad_server_count | The number of Nomad servers | number | "3" | no
| nomad_client_count | The number of Nomad clients | number | "1" | no
| private_subnet_with_nat_gw | Indicates whether Nomad nodes can reach Internet via its Private IP | bool | "false" | no
| instance_type_server | Nomad server EC2 instance type | string | "t2.micro" | no
| instance_type_client | Nomad client EC2 instance type | string | "t2.micro" | no
| instance_type_frontend | Nomad frontend EC2 instance type | string | "t2.micro" | no
| ingress_tcp_ports_nomad | The list of TCP ingress ports for Nomad | list(number) | `[4646, 4647, 4648, 22]` | no
| ingress_udp_ports_nomad | The list of UDP ingress ports for Nomad | list(number) | `[4648]` | no
| ingress_tcp_ports_frontend | The list of TCP ingress ports for Frontend | list(number) | `[80, 443, 22]` | no
| aws_vpc_id | AWS VPC id | string | - | yes
| subnet_id | AWS VPC subnet id | string | - | yes
| ami_nomad_server | Ubuntu Xenial Nomad server AWS AMI in AWS `us-east-1` region | string | `ami-0ac8c1373dae0f3e5` | no
| ami_nomad_client | Ubuntu Xenial Nomad client AWS AMI in AWS `us-east-1` region | string | `ami-02ffa51d963317aaf` | no
| ami_frontend | Ubuntu Xenial WEB Server AMI in AWS `us-east-1` region | string | `ami-090c16342ee6bb5cc` | no
| dc | Define the name of Nomad datacenter | string | "dc1" | no
| nomad_region | Define the name of Nomad region | string | "global" | no
| authoritative_region | Define the name of Nomad authoritative region | string | "global" | no
| retry_join | Used by Nomad to automatically form a cluster | string | "provider=aws tag_key=nomad-node tag_value=server" | no
| secure_gossip | Used on Nomad server instances only to enable gossip encryption | string | "null" | yes
| cloudflare_email | email of cloudflare user  | string  | `null` | yes
| cloudflare_token | cloudflare token  | string  | `null` | yes
| cloudflare_zone | The name of DNS domain  | string  | `null` | yes
| subdomain_name | The name of subdomain  | string  | `null` | yes


- Create `main.tf` file

```
module "nomad_cluster_on_aws" {
  source = "git@github.com:achuchulev/terraform-aws-nomad.git"
  
  access_key                 = var.access_key
  secret_key                 = var.secret_key
  aws_vpc_id                 = var.aws_vpc_id
  subnet_id                  = var.subnet_id
  secure_gossip              = var.secure_gossip
  cloudflare_email           = var.cloudflare_email
  cloudflare_token           = var.cloudflare_token
  cloudflare_zone            = var.cloudflare_zone
  subdomain_name             = var.subdomain_name
  private_subnet_with_nat_gw = var.private_subnet_with_nat_gw
}

```

- Create `outputs.tf` file

```
output "server_private_ips" {
  value = module.nomad_cluster_on_aws.server_private_ips
}

output "client_private_ips" {
  value = module.nomad_cluster_on_aws.client_private_ips
}

output "frontend_public_ip" {
  value = module.nomad_cluster_on_aws.frontend_public_ip
}

output "Nomad_UI_URL" {
  value = module.nomad_cluster_on_aws.ui_url
}
```

### Initialize terraform and plan/apply

```
$ terraform init
$ terraform plan
$ terraform apply
```

- `Terraform apply` will:
  - deploy nomad servers and client(s)
  - secure Nomad traffic with mutual TLS
  - deploy and configure frontnend server for UI using nginx as reverse proxy if enabled
  
  
#### Outputs

| Name  |	Description 
| ----- | ----------- 
| server_private_ips | Private IPs of Nomad servers
| client_private_ips  | Private IPs of Nomad clients
| frontend_public_ip  | Public IP of Frontend
| Nomad_UI_URL | URL of Nomad UI

## Access Nomad with CLI

- Nomad UI
- ssh to some Nomad node `ssh ubuntu@nomad_private_ip`

and 

- run for example:

```
$ nomad node status
$ nomad server members
```

## How to test

### on Mac

#### Prerequisites

##### Install selenium and all its dependencies

```
$ brew install selenium-server-standalone
$ brew cask install java

### GeckoDriver for firefox
$ brew install geckodriver 

### Chromedriver for chrome
$ brew cask install chromedriver 
```

##### Install rbenv to use ruby version 2.3.1

```
$ brew install rbenv
$ rbenv install 2.3.1
$ rbenv local 2.3.1
$ rbenv versions
```

##### Add the following lines to your ~/.bash_profile:

```
eval "$(rbenv init -)"
true
export PATH="$HOME/.rbenv/bin:$PATH"
```

##### Reload profile: 

`$ source ~/.bash_profile`

##### Install bundler

```
$ gem install bundler
$ bundle install
```

#### Run the test: 

```
$ bundle exec kitchen list
$ bundle exec kitchen converge
$ bundle exec kitchen verify
$ bundle exec kitchen destroy
```

### on Linux

#### Prerequisites

##### Install selenium and all its dependencies

```
$ gem install kitchen-terraform
$ gem install selenium-webdriver
$ apt-get install default-jdk

## GeckoDriver for firefox
$ wget https://github.com/mozilla/geckodriver/releases/download/v0.23.0/geckodriver-v0.23.0-linux64.tar.gz
$ sudo sh -c 'tar -x geckodriver -zf geckodriver-v0.23.0-linux64.tar.gz -O > /usr/bin/geckodriver'
$ sudo chmod +x /usr/bin/geckodriver
$ rm geckodriver-v0.23.0-linux64.tar.gz

## Chromedriver for chrome
$ wget https://chromedriver.storage.googleapis.com/2.29/chromedriver_linux64.zip
$ unzip chromedriver_linux64.zip
$ sudo chmod +x chromedriver
$ sudo mv chromedriver /usr/bin/
$ rm chromedriver_linux64.zip
```

#### Run kitchen test 

```
$ kitchen list
$ kitchen converge
$ kitchen verify
$ kitchen destroy
```

### Sample output

```
Target:  local://

  Command: `terraform output`
     ✔  stdout should include "client_private_ips"
     ✔  stderr should include ""
     ✔  exit_status should eq 0
  Command: `terraform output`
     ✔  stdout should include "server_private_ips"
     ✔  stderr should include ""
     ✔  exit_status should eq 0
  Command: `terraform output`
     ✔  stdout should include "frontend_public_ip"
     ✔  stderr should include ""
     ✔  exit_status should eq 0
  HTTP GET on https://nomad-ui.example.com/ui/jobs
     ✔  status should cmp == 200

Test Summary: 10 successful, 0 failures, 0 skipped
```
