output "public_ip" {
  value = aws_instance.k3s_node.public_ip
}
