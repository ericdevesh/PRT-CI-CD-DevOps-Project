output "k8s_node_public_ip" {
  description = "Public IPv4 address of Terraform-created k8s-node"
  value       = aws_instance.k8s_node.public_ip
}

output "k8s_node_public_dns" {
  description = "Public DNS name of k8s-node"
  value       = aws_instance.k8s_node.public_dns
}
