variable "region" {
    description = "AWS Region to deploy resources"
    type = string
    default = "us-east-1"
}

variable "vpc_cidr_block" {
    description = "VPC cidr block"
    type = string
    default = "10.0.0.0/16"
}