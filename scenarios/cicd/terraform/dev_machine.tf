data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}
resource "aws_network_interface" "dev" {
  subnet_id   = module.vpc.private_subnets[0]
  private_ips = ["10.0.1.10"]
}
resource "aws_iam_role" "dev-instance" {
  name = "dev-instance-role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "dev-instance-policy" {
  role       = aws_iam_role.dev-instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_instance_profile" "dev" {
  name = "dev-instance-profile"
  role = aws_iam_role.dev-instance.name
}
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}
resource "aws_instance" "dev" {
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = "t3.micro"
  iam_instance_profile = aws_iam_instance_profile.dev.name
  user_data            = templatefile("${path.module}/../assets/dev-machine/provision.sh", { private_ssh_key = tls_private_key.ssh_key.private_key_pem })
  subnet_id            = module.vpc.private_subnets[0]

  security_groups = [
    aws_security_group.allow_egress.id
  ]

  tags = {
    Name        = "dev-instance",
    Environment = "dev"
  }
}

resource "aws_security_group" "allow_egress" {
  name        = "allow_egress"
  description = "Allow server to communicate with AWS SSM"
  vpc_id      = module.vpc.vpc_id

  egress {
    description      = "Allow communication between session manager and the server"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "cicd_allow_egress"
  }
}

# IAM user
resource "aws_iam_user" "readonly_user" {
  name = local.repo_readonly_username
}
resource "aws_iam_user_ssh_key" "readonly_user" {
  username   = aws_iam_user.readonly_user.name
  encoding   = "SSH"
  public_key = tls_private_key.ssh_key.public_key_openssh
}
resource "aws_iam_user_policy" "readonly_user" {
  name = "readonly_user-policy"
  user = aws_iam_user.readonly_user.name

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": "${aws_codecommit_repository.code.arn}",
      "Action": [
          "codecommit:GitPull"
      ]
    },
    {
      "Effect": "Allow",
      "Resource": "*",
      "Action": [
          "codecommit:Get*",
          "codecommit:List*"
      ]
    }
  ]
}
POLICY

}
