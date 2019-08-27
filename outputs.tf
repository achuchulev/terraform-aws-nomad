# output "instance_public_ip" {
#   value = aws_instance.nomad_instance.*.public_ip
# }

output "instance_private_ip" {
  value = formatlist(
    "%s %s:%s;",
    "server",
    aws_instance.nomad_instance.*.private_ip,
    "4646",
  )
}

output "private_ips" {
  value = aws_instance.nomad_instance.*.private_ip
}

# output "instance_public_dns" {
#   value = aws_instance.nomad_instance.*.public_dns
# }

output "instance_tags" {
  value = aws_instance.nomad_instance.*.tags
}

