output "private_ips" {
  value = aws_instance.nomad_instance.*.private_ip
}

output "nomad_ui_sockets" {
  value = formatlist(
    "%s %s:%s;",
    "server",
    aws_instance.nomad_instance.*.private_ip,
    "4646",
  )
}

output "instance_tags" {
  value = aws_instance.nomad_instance.*.tags
}
