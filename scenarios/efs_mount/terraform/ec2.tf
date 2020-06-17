#IAM Role
resource "aws_iam_role" "cg-ecsTaskExecutionRole-role" {
  name = "cg-ec2-role-${var.cgid}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags = {
      Name = "cg-ec2-role-${var.cgid}"
      Stack = "${var.stack-name}"
      Scenario = "${var.scenario-name}"
  }
}


#IAM Admin Role

resource "aws_iam_role" "cg-efs-admin-role" {
  name = "cg-efs-admin-role-${var.cgid}"
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
  tags = {
      Name = "cg-ec2-efsUser-role-${var.cgid}"
      Stack = "${var.stack-name}"
      Scenario = "${var.scenario-name}"
  }
}



#Iam Role Policy
resource "aws_iam_policy" "cg-ecsTaskExecutionRole-ruse-role-policy" {
  name = "cg-ecsTaskExecutionRole-ruse-role-policy-${var.cgid}"
  description = "cg-ecsTaskExecutionRole-ruse-role-policy-${var.cgid}"
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
              "ecr:GetAuthorizationToken",
              "ecr:BatchCheckLayerAvailability",
              "ecr:GetDownloadUrlForLayer",
              "ecr:BatchGetImage",
              "logs:CreateLogStream",
              "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
POLICY
}

resource "aws_iam_policy" "cg-efs-admin-role-policy" {
  name = "cg-efs-admin-role-policy-${var.cgid}"
  description = "cg-efs-admin-role-policy-${var.cgid}"
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
              "elasticfilesystem:ClientMount"
            ],
            "Resource": "*"
        }
    ]
}
POLICY
}





#IAM Role Policy Attachment
resource "aws_iam_policy_attachment" "cg-ecsTaskExecutionRole-ruse-role-policy-attachment" {
  name = "cg-ecsTaskExecutionRole-ruse-role-policy-attachment-${var.cgid}"
  roles = [
      "${aws_iam_role.cg-ecsTaskExecutionRole-role.name}"
  ]
  policy_arn = "${aws_iam_policy.cg-ecsTaskExecutionRole-ruse-role-policy.arn}"
}

resource "aws_iam_policy_attachment" "cg-efs-admin-role-policy-attachment" {
  name = "cg-efs-admin-role-policy-attachment-${var.cgid}"
  roles = [
      "${aws_iam_role.cg-efs-admin-role.name}"
  ]
  policy_arn = "${aws_iam_policy.cg-efs-admin-role-policy.arn}"
}


#IAM Instance Profile
resource "aws_iam_instance_profile" "cg-ecsTaskExecutionRole-instance-profile" {
  name = "cg-ecsTaskExecutionRole-instance-profile-${var.cgid}"
  role = "${aws_iam_role.cg-ecsTaskExecutionRole-role.name}"
}

resource "aws_iam_instance_profile" "cg-efs-admin-instance-profile" {
  name = "cg-efs-admin-instance-profile-${var.cgid}"
  role = "${aws_iam_role.cg-efs-admin-role.name}"
}

#Security Groups
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

#AWS Key Pair
resource "aws_key_pair" "cg-ec2-key-pair" {
  key_name = "cg-ec2-key-pair-${var.cgid}"
  public_key = "${file(var.ssh-public-key-for-ec2)}"
}
#EC2 Instance
resource "aws_instance" "cg-ruse-ec2" {
    ami = "ami-0a313d6098716f372"
    instance_type = "t2.micro"
    iam_instance_profile = "${aws_iam_instance_profile.cg-ecsTaskExecutionRole-instance-profile.name}"
    subnet_id = "${aws_subnet.cg-public-subnet-1.id}"
    associate_public_ip_address = true
    vpc_security_group_ids = [
        "${aws_security_group.cg-ec2-ssh-security-group.id}"
    ]
    key_name = "${aws_key_pair.cg-ec2-key-pair.key_name}"
    root_block_device {
        volume_type = "gp2"
        volume_size = 8
        delete_on_termination = true
    }
   
    volume_tags = {
        Name = "CloudGoat ${var.cgid} EC2 Instance Root Device"
        Stack = "${var.stack-name}"
        Scenario = "${var.scenario-name}"
    }
    tags = {
        Name = "cg-ruse-ec2-${var.cgid}"
        Stack = "${var.stack-name}"
        Scenario = "${var.scenario-name}"
    }
}


resource "aws_instance" "cg-dev-ec2" {
    ami = "ami-0a313d6098716f372"
    instance_type = "t2.micro"
    iam_instance_profile = "${aws_iam_instance_profile.cg-efs-admin-instance-profile.name}"
    subnet_id = "${aws_subnet.cg-public-subnet-1.id}"
    associate_public_ip_address = false
    vpc_security_group_ids = [
        "${aws_security_group.cg-ec2-ssh-security-group.id}"
    ]
    key_name = "${aws_key_pair.cg-ec2-key-pair.key_name}"
    root_block_device {
        volume_type = "gp2"
        volume_size = 8
        delete_on_termination = true
    }
   
    volume_tags = {
        Name = "CloudGoat ${var.cgid} EC2 Instance Root Device"
        Stack = "${var.stack-name}"
        Scenario = "${var.scenario-name}"
    }
    tags = {
        Name = "cg-efs-admin-ec2-${var.cgid}"
        Stack = "${var.stack-name}"
        Scenario = "${var.scenario-name}"
    }
}
