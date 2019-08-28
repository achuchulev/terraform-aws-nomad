data_dir  = "/opt/nomad"

region = "$1"

datacenter = "$2"

bind_addr = "0.0.0.0"

client {
  enabled = true
  server_join {
    retry_join = ["$4"]
    retry_max = 5
    retry_interval = "15s"
  }
  options = {
    "driver.raw_exec" = "1"
    "driver.raw_exec.enable" = "1"
  }
}

# Require TLS
tls {
  http = true
  rpc  = true

  ca_file   = "/home/ubuntu/nomad/ssl/nomad-ca.pem"
  cert_file = "/home/ubuntu/nomad/ssl/client.pem"
  key_file  = "/home/ubuntu/nomad/ssl/client-key.pem"

  verify_server_hostname = true
  verify_https_client    = true
}
