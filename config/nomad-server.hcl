data_dir  = "/opt/nomad"

region = "$1"

datacenter = "$2"

bind_addr = "0.0.0.0"

server {
  enabled = true
  bootstrap_expect = 3
  authoritative_region = "$3"
  server_join {
    retry_join = ["$4"]
    retry_max = 5
    retry_interval = "15s"
  }

  encrypt = "$5"
}

# Require TLS
tls {
  http = true
  rpc  = true

  ca_file   = "/home/ubuntu/nomad/ssl/nomad-ca.pem"
  cert_file = "/home/ubuntu/nomad/ssl/server.pem"
  key_file  = "/home/ubuntu/nomad/ssl/server-key.pem"

  verify_server_hostname = true
  verify_https_client    = true
}
