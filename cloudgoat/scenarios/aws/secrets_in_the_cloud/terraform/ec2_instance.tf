# This is a Terraform file that creates several AWS EC2 resources:
# 1. A Data Source for an AWS Amazon Machine Image.
# 2. A TLS Private Key Resource
# 3. An AWS Key Pair Resource
# 4. An AWS Instance Resource
# 5. An AWS Security Group Resource

resource "tls_private_key" "id_rsa" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "id_rsa" {
  key_name   = "idrsa-keypair"
  public_key = tls_private_key.id_rsa.public_key_openssh
}

resource "aws_instance" "web_app" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.id_rsa.key_name
  subnet_id     = aws_subnet.subnet.id

  vpc_security_group_ids = [
    aws_security_group.web_app_sg.id,
  ]

  user_data = base64encode(templatefile("templates/user_data.tpl", {
    aws_access_key_id     = aws_iam_access_key.secrets_manager_user_key.id,
    aws_secret_access_key = aws_iam_access_key.secrets_manager_user_key.secret,
    private_key           = tls_private_key.id_rsa.private_key_pem,
  }))

  # This sets the EC2 instance's IAM instance profile to the Dynamo DB profile created in iam.tf
  iam_instance_profile = aws_iam_instance_profile.dynamodb_instance_profile.name

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name = "CloudGoat Secrets in the Cloud Web App"
  }
}

resource "aws_security_group" "web_app_sg" {
  name        = "web_app_sg-${var.cgid}"
  description = "Allow inbound traffic to the web app and Vault"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.cg_whitelist
  }

  ingress {
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = var.cg_whitelist
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.cg_whitelist
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }
}
