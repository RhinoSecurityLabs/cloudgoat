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

resource "aws_instance" "instance_1" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  iam_instance_profile = "${aws_iam_instance_profile.ec2_instance_profile.name}"

  tags = {
    tag-key = "${var.cgid}"
  }
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "${var.target_CIDR_block}"

  tags = {
    tag-key = "${var.cgid}"
  }
}

resource "aws_security_group" "main" {
  name        = "${var.cgid}"
  description = "Allow ssh inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "SSH"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    tag-key = "${var.cgid}"
  }
}