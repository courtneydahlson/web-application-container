output "backend_alb_dns_name" {
    description = "The DNS name for the backend ALB"
    value = aws_lb.backend_alb.dns_name
}

output "aurora_cluster_endpoint" {
    description = "Aurora cluster writer endpoint"
    value = aws_rds_cluster.aurora_cluster.endpoint
}

output "aurora_cluster_reader_endpoint" {
    description = "Aurora cluster reader endpoint"
    value = aws_rds_cluster.aurora_cluster.reader_endpoint
}

output "aurora_instance_endpoint" {
    description = "Aurora instance endpoint"
    value = aws_rds_cluster_instance.aurora_instance.endpoint
}