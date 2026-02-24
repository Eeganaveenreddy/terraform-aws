resource "aws_lb_listener_certificate" "additional_https_certs" {
  for_each = toset(var.additional_acm_certificate_arns)

  listener_arn    = var.https_listener_arn
  certificate_arn = each.value
}
