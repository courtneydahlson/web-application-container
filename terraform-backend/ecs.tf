# ECS Cluster
resource "aws_ecs_cluster" "main" {
    name = "web-application-cluster"
}

# Task Definition
resource "aws_ecs_task_definition" "flask_web_app_td" {
    family = "flask_web_app"
    network_mode = "awsvpc"
    requires_compatibilities = ["FARGATE"]
    cpu = "256"
    memory = "512"
    execution_role_arn = aws_iam_role.ecs_task_execution.arn

    container_definitions = jsonencode([
        {
            name = "web_application_container",
            image = "783764614133.dkr.ecr.us-east-1.amazonaws.com/web-application-container-repo:latest",
            essential = true,
            portMappings = [
                {
                    containerPort = 8080,
                    hostPort = 8080,
                    protocol = "tcp" 
                }
            ]
        }
    ])
}

# ECS Service
resource "aws_ecs_service" "flask_web_app_service" {
    name = "web-application-service"
    cluster = aws_ecs_cluster.main.id
    task_definition = aws_ecs_task_definition.flask_web_app_td.arn
    launch_type = "FARGATE"
    desired_count = 1

    network_configuration {
        subnets = [
            aws_subnet.private_subnet_1.id,
            aws_subnet.private_subnet_2.id
        ]
        security_groups = [aws_security_group.ecs_sg.id]
        assign_public_ip = false
    }

    load_balancer {
        target_group_arn = aws_lb_target_group.backend_tg.arn
        container_name = "web-application-container"
        container_port = 8080
    }

    depends_on = [aws_lb.backend_alb, aws_lb_listener.https_listener, aws_lb_listener.http_redirect]
}

# ECS Security Group
resource "aws_security_group" "ecs_sg" {
    vpc_id = aws_vpc.main.id

    ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_backend_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
