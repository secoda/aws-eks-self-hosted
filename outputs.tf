
data "aws_lb" "secoda" {
  name = "${var.name_identifier}-lb"
  tags = { "elbv2.k8s.aws/cluster" : var.name_identifier }
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "ingress_dns_name" {
  description = "DNS Name for ALB Ingress"
  value       = data.aws_lb.secoda.dns_name
}

output "nat_ip_address" {
  description = "VPN NAT Gateway IP Address"
  value       = module.vpc.nat_public_ips
}
