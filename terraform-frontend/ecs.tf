# Task Definition
resource "aws_ecs_task_definition" "frontend_td" {
    family = "frontend-webserver"
    network_mode = "awsvpc"
    requires_compatibilities = ["FARGATE"]
    cpu = "256"
    memory = "512"
    execution_role_arn = data.aws_iam_role.ecs_task_execution.arn

    container_definitions = jsonencode([
        {
            name = "frontend-container",
            image = "783764614133.dkr.ecr.us-east-1.amazonaws.com/frontend-container-repo:latest",
            essential = true,
            portMappings = [
                {
                    containerPort = 80,
                    protocol = "tcp" 
                }
            ]
        }
    ])
}

# ECS Service
resource "aws_ecs_service" "frontend_service" {
    name = "frontend-service"
    cluster = data.aws_ecs_cluster.main.id
    task_definition = aws_ecs_task_definition.frontend_td.arn
    launch_type = "FARGATE"
    desired_count = 3

    network_configuration {
        subnets = [
            data.aws_subnet.private_subnet_1.id,
            data.aws_subnet.private_subnet_2.id
        ]
        security_groups = [aws_security_group.ecs_frontend_sg.id]
        assign_public_ip = false
    }

    load_balancer {
        target_group_arn = aws_lb_target_group.frontend_tg.arn
        container_name = "frontend-container"
        container_port = 80
    }

    depends_on = [aws_lb.frontend_alb, aws_lb_listener.https_listener, aws_lb_listener.http_redirect]
}

# ECS Security Group
resource "aws_security_group" "ecs_frontend_sg" {
    vpc_id = data.aws_vpc.main.id

    ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_frontend_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
