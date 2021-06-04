resource "aws_ecr_repository" "repo" {
    name  = "repo"

    provisioner "local-exec" {
        command = "aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin ${aws_ecr_repository.repo.repository_url}; docker build -t repo ./website/ ; docker tag repo:latest ${aws_ecr_repository.repo.repository_url}:latest ; docker push ${aws_ecr_repository.repo.repository_url}:latest"
    }
}

resource "aws_ecs_cluster" "ecs_cluster" {
    name  = "my-cluster"
}