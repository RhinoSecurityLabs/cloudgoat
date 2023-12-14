resource "aws_ecr_repository" "repository" {
  name = "cg-repository-${var.cgid}"
}

resource "null_resource" "docker_image" {
  # Push Docker image when the scenario be created
  provisioner "local-exec" {
    when    = create
    command = "python ./push-dockerfile.py --repository ${aws_ecr_repository.repository.name} --region ${var.region} --profile ${var.profile} --image_tag latest"
  }

  # Pop Docker images when the scenario be destroyed
  provisioner "local-exec" {
    when    = destroy
    command = "python ./pop-dockerfile.py --repository ${self.triggers.repository_name} --region ${self.triggers.region} --profile ${self.triggers.profile} --image_tag all"
  }

  triggers = {
    repository_name = aws_ecr_repository.repository.name
    region          = var.region
    profile         = var.profile
  }

  depends_on = [aws_ecr_repository.repository]
}