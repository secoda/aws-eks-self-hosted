resource "aws_acm_certificate" "secoda" {
  count = var.acm_lb_cert_arn == "" ? 1 : 0
  domain_name       = var.fqdn
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  aws_acm_arn = var.acm_lb_cert_arn == "" ? aws_acm_certificate.secoda[0].arn : var.acm_lb_cert_arn
}

resource "aws_acm_certificate_validation" "secoda" {
  certificate_arn = local.aws_acm_arn
}
