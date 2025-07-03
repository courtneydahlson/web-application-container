resource "aws_ecr_repository" "my_app" {
    name = "web-application-container-repo"

    image_tag_mutability = "MUTABLE"
    image_scanning_configuration {
      scan_on_push = true
    }

    tags = {
        Environment = "dev"
        Name = "web-application-container-repo"
    }
}

resource "aws_ecr_lifecycle_policy" "my_app_policy" {
    repository = aws_ecr_repository.my_app.name

    policy = jsonencode({
        rules = [
            {
                rulePriority = 2
                description = "Keep only last 10 images"
                selection = {
                    tagStatus = "any"
                    countType = "imageCountMoreThan"
                    countNumber = 10
                }
                action = {
                    type = "expire"
                }
            },
            {
                rulePriority = 1
                description = "Expire images older than 14 days"
                selection = {
                    tagStatus = "untagged"
                    countType = "sinceImagePushed"
                    countUnit = "days"
                    countNumber = 14
                }
                action = {
                    type = "expire"
                }
            }
        ]
    })
}