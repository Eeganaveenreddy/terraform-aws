variable "https_listener_arn" {
  description = "HTTPS listener ARN where ACM certificates will be attached"
  type        = string
}

variable "additional_acm_certificate_arns" {
  description = "Additional ACM certificate ARNs to attach to the HTTPS listener (SNI)"
  type        = list(string)
  default     = []
}
