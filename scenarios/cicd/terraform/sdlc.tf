resource "aws_codecommit_repository" "code" {
  repository_name = local.repository_name
}

locals {
  // Note: templatefile only works if the template is in the Terraform folder
  vulnerable_file_content = templatefile("${path.module}/vulnerable-buildspec.yml.tftpl", {
    aws_access_key_id     = aws_iam_access_key.developer.id,
    aws_secret_access_key = aws_iam_access_key.developer.secret
  })
  src_path = "${abspath(path.module)}/../assets/src"
}
resource "null_resource" "upload_files" {
  depends_on = [
    aws_codebuild_project.build-docker-image,
    aws_iam_role_policy.build-docker-image,
    aws_codecommit_repository.code,
  ]

  provisioner "local-exec" {
    working_dir = path.module
    on_failure  = fail
    interpreter = ["bash", "-c"]
    environment = {
      AWS_REGION = var.region,
      AWS_DEFAULT_REGION = var.region
      AWS_PROFILE = var.profile
      AWS_DEFAULT_PROFILE = var.profile
    }
    
    command     = <<BASH
    set -e
    cat > "${local.src_path}/buildspec.old.yml" <<EOF
      ${local.vulnerable_file_content}
EOF
    commit=$(aws codecommit put-file --repository-name "${local.repository_name}" --branch-name master --file-content "fileb://${local.src_path}/buildspec.old.yml" --file-path buildspec.yml --output text --query commitId);
    commit=$(aws codecommit put-file --repository-name "${local.repository_name}" --branch-name master --file-content "fileb://${local.src_path}/buildspec.yml" --file-path buildspec.yml --commit-message "Use built-in AWS authentication instead of hardcoded keys" --parent-commit-id $commit --output text --query commitId);
    commit=$(aws codecommit put-file --repository-name "${local.repository_name}" --branch-name master --file-content "fileb://${local.src_path}/Dockerfile" --file-path Dockerfile --parent-commit-id $commit --output text --query commitId);
    commit=$(aws codecommit put-file --repository-name "${local.repository_name}" --branch-name master --file-content "fileb://${local.src_path}/requirements.txt" --file-path requirements.txt --parent-commit-id $commit --output text --query commitId);
    commit=$(aws codecommit put-file --repository-name "${local.repository_name}" --branch-name master --file-content "fileb://${local.src_path}/app.py" --file-path app.py --parent-commit-id $commit --output text --query commitId);    
    aws codebuild start-build --project-name "${aws_codebuild_project.build-docker-image.name}";
    statusCode=1;
    imageDigest="";
    while [[ "$statusCode" != 0 ]] || [[ "$imageDigest" -eq "None" ]]; do 
      echo "Waiting for ECR image to be ready..."; 
      sleep 5; 
      imageDigest=$(aws ecr list-images --repository-name "${local.ecr_repository_name}" --query 'imageIds[0].imageDigest' --output text 2>/dev/null);
      statusCode=$?; 
    done
BASH
  }


}

resource "aws_ecr_repository" "app" {
  name                 = local.ecr_repository_name
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

