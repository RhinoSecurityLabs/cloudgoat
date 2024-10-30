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
  output_path = "my_flask_app.zip"
  source_dir  = "source/flask/"
}
