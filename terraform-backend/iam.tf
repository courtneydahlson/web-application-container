resource "aws_iam_role" "ecs_task_execution" {
    name = "ecsTaskExecutionAppRole-tf"
    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [{
            Action = "sts:AssumeRole",
            Effect = "Allow",
            Principal = {
                Service = "ecs-tasks.amazonaws.com"
            }
        }]
    })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
    role = aws_iam_role.ecs_task_execution.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
    name = "ecs-task-role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect = "Allow",
            Principal = {
                Service = "ecs-tasks.amazonaws.com"
            },
            Action = "sts:AssumeRole"
        }]
    })
}

# Secrets manager policy
resource "aws_iam_role_policy" "ecs_secrets_policy" {
    name = "ECSSecretsAccessPolicy"
    role = aws_iam_role.ecs_task_role.id
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
        }]
    })
}

