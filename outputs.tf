output "server_private_ips" {
  value = aws_instance.nomad_server.*.private_ip
}

output "client_private_ips" {
  value = aws_instance.nomad_client.*.private_ip
}

output "frontend_public_ip" {
  value = aws_instance.frontend.*.public_ip
}

output "ui_url" {
  value = var.ui_enabled == "true" ? "https://${var.subdomain_name}.${var.cloudflare_zone}" : "Nomad UI is not enabled!"
}
