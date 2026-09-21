output "public_ip" {
  description = "Public IPv4 of the demo VM."
  value       = aws_instance.demo.public_ip
}

output "demo_url" {
  description = "HTTP URL for the web frontend. Reachable only from allowed_cidr."
  value       = "http://${aws_instance.demo.public_ip}"
}

output "allowed_cidr" {
  description = "CIDR allowed through the NSG (security group) for SSH and HTTP."
  value       = local.allowed_cidr
}

output "ssh_user" {
  description = "OS user for Amazon Linux 2023."
  value       = "ec2-user"
}

output "instance_id" {
  description = "EC2 instance id."
  value       = aws_instance.demo.id
}
