resource "aws_instance" "cg_admin_ec2" {
  ami           = var.ami_id
  instance_type = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.cg_ec2_role.name

  tags = {
    Name = "cg_admin_ec2"
  }
}

output "account_id" {
  value = data.aws_caller_identity.aws-account-id.account_id
}

