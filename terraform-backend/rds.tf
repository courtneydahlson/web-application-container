resource "aws_db_subnet_group" "rds_subnets" {
  name       = "rds-subnet-group-tf"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
}

# RDS Security Group
resource "aws_security_group" "rds_sg" {
  name   = "rds-sg-tf"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Retrieve Credentials from secrets manager
data "aws_secretsmanager_secret" "rds_creds" {
  name = "rds/mysql"
}

data "aws_secretsmanager_secret_version" "rds_creds" {
  secret_id = data.aws_secretsmanager_secret.rds_creds.id
}

locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.rds_creds.secret_string)
}

# Create Aurora Cluster (writer endpoint)
resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier      = "backend-aurora-cluster"
  engine                  = "aurora-mysql"
  engine_version          = "8.0.mysql_aurora.3.08.2" 
  database_name           = "webappdb"
  master_username         = local.db_creds.username
  master_password         = local.db_creds.password
  db_subnet_group_name    = aws_db_subnet_group.rds_subnets.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  skip_final_snapshot     = true
  backup_retention_period = 1
}

# Create instance (The first instance created will be the writer)
resource "aws_rds_cluster_instance" "aurora_instance" {
  identifier              = "aurora-mysql-instance"
  cluster_identifier      = aws_rds_cluster.aurora_cluster.id
  instance_class          = "db.r5.large"  
  engine                  = "aurora-mysql"  
  publicly_accessible     = false
  db_subnet_group_name    = aws_db_subnet_group.rds_subnets.name
  tags = {
    Name = "AuroraInstance"
  }
}


resource "aws_secretsmanager_secret" "rds_writer_endpoint" {
    name = "rds-writer-endpoint"
    description = "Stores the writer endpoint"
}

resource "aws_secretsmanager_secret_version" "rds_writer_endpoint_version" {
    secret_id = aws_secretsmanager_secret.rds_writer_endpoint.id
    secret_string = jsonencode({
        endpoint = aws_rds_cluster.aurora_cluster.endpoint
    })

    depends_on = [aws_rds_cluster.aurora_cluster]
    }