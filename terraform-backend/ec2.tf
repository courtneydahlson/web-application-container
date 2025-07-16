resource "aws_iam_role" "ec2_role" {
  name = "ec2-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

data "aws_caller_identity" "current" {}

# Secrets manager policy
resource "aws_iam_policy" "secrets_policy" {
  name = "SecretsAccessPolicy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # Allow reading secret values
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Resource = "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_secrets_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.secrets_policy.arn
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# Security group
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-instance-sg"
  description = "Allow EC2 to connect to RDS"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


#EC2 Instance in Public Subnet
resource "aws_instance" "table" {
  ami                    = "ami-05ffe3c48a9991133"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet_1.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true
  key_name               = "EC2 Tutorial"

  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  depends_on = [aws_rds_cluster.aurora_cluster]

  user_data = base64encode(file("userdata.sh"))

}


