resource "aws_ecr_repository" "frontend_repo" {
    name = "frontend-container-repo"

    image_tag_mutability = "MUTABLE"
    image_scanning_configuration {
      scan_on_push = true
    }

    tags = {
        Environment = "dev"
        Name = "frontend-container-repo"
    }
}

resource "aws_ecr_lifecycle_policy" "frontend_repo_policy" {
    repository = aws_ecr_repository.frontend_repo.name

    policy = jsonencode({
        rules = [
            {
                rulePriority = 2
                description = "Keep only last 5 images"
                selection = {
                    tagStatus = "any"
                    countType = "imageCountMoreThan"
                    countNumber = 5
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