


# IAM Role Policy Attachment
resource "aws_iam_policy_attachment" "cg-ec2-ruse-role-policy-attachment" {
  name = "cg-ec2-ruse-role-policy-attachment-${var.cgid}"
  roles = [
      "${aws_iam_role.cg-ec2-ruse-role.name}"
  ]
  policy_arn = "${aws_iam_policy.cg-ec2-ruse-role-policy.arn}"
}

resource "aws_iam_policy_attachment" "cg-efs-admin-role-policy-attachment" {
  name = "cg-efs-admin-role-policy-attachment-${var.cgid}"
  roles = [
      "${aws_iam_role.cg-efs-admin-role.name}"
  ]
  policy_arn = "${aws_iam_policy.cg-efs-admin-role-policy.arn}"
}

resource "aws_iam_policy_attachment" "cg-ssm-mangaged" {
  name = "cg-cg-ssm-mangaged-role-policy-attachment-${var.cgid}"
  roles = [
      "${aws_iam_role.cg-efs-admin-role.name}",
      "${aws_iam_role.cg-ec2-ruse-role.name}"
  ]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}



# IAM Instance Profile
resource "aws_iam_instance_profile" "cg-ec2-ruse-instance-profile" {
  name = "cg-ecsTaskExecutionRole-instance-profile-${var.cgid}"
  role = "${aws_iam_role.cg-ec2-ruse-role.name}"
}

resource "aws_iam_instance_profile" "cg-efs-admin-instance-profile" {
  name = "cg-efs-admin-instance-profile-${var.cgid}"
  role = "${aws_iam_role.cg-efs-admin-role.name}"
}

# Security Groups
resource "aws_security_group" "cg-ec2-ssh-security-group" {
  name = "cg-ec2-ssh-${var.cgid}"
  description = "CloudGoat ${var.cgid} Security Group for EC2 Instance over SSH"
  vpc_id = "${aws_vpc.cg-vpc.id}"
  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = var.cg_whitelist
  }
  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = [
          "0.0.0.0/0"
      ]
  }
  tags = {
    Name = "cg-ec2-ssh-${var.cgid}"
    Stack = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}


resource "aws_security_group" "cg-ec2-efs-security-group" {
  name = "cg-ec2-efs-${var.cgid}"
  description = "CloudGoat ${var.cgid} Security Group for EFS"
  vpc_id = "${aws_vpc.cg-vpc.id}"
  ingress {
      from_port = 2049
      to_port = 2049
      protocol = "tcp"
      cidr_blocks = [
          "0.0.0.0/0"
      ]
  }
  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = [
          "0.0.0.0/0"
      ]
  }
  tags = {
    Name = "cg-ec2-efs-${var.cgid}"
    Stack = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}


resource "aws_security_group" "cg-ec2-http-listener-security-group" {
  name = "cg-ec2-http-${var.cgid}"
  description = "CloudGoat ${var.cgid} Security Group for http server"
  vpc_id = "${aws_vpc.cg-vpc.id}"
  ingress {
      from_port = 8080
      to_port = 8080
      protocol = "tcp"
      cidr_blocks = [
          "0.0.0.0/0"
      ]
  }
  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = [
          "0.0.0.0/0"
      ]
  }
  tags = {
    Name = "cg-ec2-http-${var.cgid}"
    Stack = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}

# AWS Key Pair
resource "aws_key_pair" "cg-ec2-key-pair" {
  key_name = "cg-ec2-key-pair-${var.cgid}"
  public_key = "${file(var.ssh-public-key-for-ec2)}"
}

# EC2 Instance "ruse-box"
resource "aws_instance" "cg-ruse-ec2" {
    ami = "ami-0a313d6098716f372"
    instance_type = "t2.micro"
    iam_instance_profile = "${aws_iam_instance_profile.cg-ec2-ruse-instance-profile.name}"
    subnet_id = "${aws_subnet.cg-public-subnet-1.id}"
    associate_public_ip_address = true
    
    # Open ssh to whitelist ip and 8080 extenally 
    vpc_security_group_ids = [
        "${aws_security_group.cg-ec2-ssh-security-group.id}",
        "${aws_security_group.cg-ec2-http-listener-security-group.id}"
    ]
    key_name = "${aws_key_pair.cg-ec2-key-pair.key_name}"
    root_block_device {
        volume_type = "gp2"
        volume_size = 8
        delete_on_termination = true
    }


    user_data = <<-EOF
      #! /bin/bash
      sudo snap start amazon-ssm-agent  
      sudo apt-get update
      sudo apt-get install -y unzip
      curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
      unzip awscliv2.zip
      sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update
      curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
      sudo dpkg -i session-manager-plugin.deb
      EOF
   
    volume_tags = {
        Name = "CloudGoat ${var.cgid} EC2 Instance Root Device"
        Stack = "${var.stack-name}"
        Scenario = "${var.scenario-name}"
    }
    tags = {
        Name = "cg-ruse-ec2-${var.cgid}"
        Stack = "${var.stack-name}"
        StartSession = "true"
        Scenario = "${var.scenario-name}"
    }
}


resource "aws_instance" "cg-dev-ec2" {
    ami = "ami-0a313d6098716f372"
    instance_type = "t2.micro"
    iam_instance_profile = "${aws_iam_instance_profile.cg-efs-admin-instance-profile.name}"
    subnet_id = "${aws_subnet.cg-public-subnet-1.id}"
    associate_public_ip_address = true
    
    # Open port for efs 
    vpc_security_group_ids = [
        "${aws_security_group.cg-ec2-efs-security-group.id}"
    ]

    root_block_device {
        volume_type = "gp2"
        volume_size = 8
        delete_on_termination = true
    }


    user_data = <<-EOF
      #! /bin/bash
      sudo snap start amazon-ssm-agent  
      sudo apt-get update
      sudo apt-get install -y nfs-common
      sudo apt-get install -y unzip
      curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
      unzip awscliv2.zip
      sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update
      sudo apt install nmap

      EOF
   
    volume_tags = {
        Name = "CloudGoat ${var.cgid} EC2 Instance Root Device"
        Stack = "${var.stack-name}"
        Scenario = "${var.scenario-name}"
    }
    tags = {
        Name = "cg-admin-ec2-${var.cgid}"
        Stack = "${var.stack-name}"
        StartSession = "false"
        Scenario = "${var.scenario-name}"
    }
}
