output "backend_alb_dns_name" {
    description = "The DNS name for the backend ALB"
    value = aws_lb.backend_alb.dns_name
}
