output "public_ip" {
  description = "Origin Elastic IPv4. The Cloudflare-proxied A record points here; it is not the address browsers resolve."
  value       = aws_eip.demo.public_ip
}

output "hostname" {
  description = "Public DNS name served by Cloudflare (browser HTTPS)."
  value       = var.hostname
}

output "demo_url" {
  description = "HTTPS URL at the Cloudflare edge."
  value       = "https://${var.hostname}"
}

output "allowed_cidr" {
  description = "CIDR allowed through the NSG for SSH."
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
