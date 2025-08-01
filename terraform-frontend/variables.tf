variable "region" {
    description = "AWS Region to deploy resources"
    type = string
    default = "us-east-1"
}

variable "certificate_arn" {
  description = "Certificate for frontend"
}
