# IAM Role for EC2
resource "aws_iam_role" "cg-ec2-sns-role" {
  name = "cg-ec2-sns-role-${var.cgid}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

# IAM Role Policy for EC2
resource "aws_iam_role_policy" "cg-ec2-sns-policy" {
  name   = "cg-ec2-sns-policy-${var.cgid}"
  role   = aws_iam_role.cg-ec2-sns-role.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sns:Publish",
                "sns:Subscribe",
                "sns:Receive"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

# Attach the IAM Role to an EC2 instance
resource "aws_iam_instance_profile" "cg-ec2-sns-instance-profile" {
  name = "cg-ec2-sns-instance-profile-${var.cgid}"
  role = aws_iam_role.cg-ec2-sns-role.name
}
