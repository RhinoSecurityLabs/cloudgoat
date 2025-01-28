data "archive_file" "flask_app" {
  type        = "zip"
  output_path = "my_flask_app.zip"
  source_dir  = "source/flask/"
}

data "archive_file" "lambda_function" {
  type        = "zip"
  source_file = "source/lambda_function.py"
  output_path = "source/lambda_function.zip"
}


data "aws_ami" "ubuntu_image" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-amd64-server-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
