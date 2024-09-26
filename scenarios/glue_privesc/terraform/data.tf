data "aws_ami" "latest_amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

data "archive_file" "flask_app" {
  type        = "zip"
  output_path = "lambda.zip"
  source_dir  = "source/flask/"
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "source/s3_to_gluecatalog.py"
  output_path = "s3_to_gluecatalog.zip"
}
