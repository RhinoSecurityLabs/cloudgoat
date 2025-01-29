resource "aws_instance" "cg_admin_ec2" {
  ami           = var.ami_id
  instance_type = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.cg_ec2_role.name

  # Specify the VPC's private subnet
  subnet_id = aws_subnet.cg_private_subnet.id

  # Tags for the instance
  tags = {
    Name = "cg_admin_ec2_${var.cgid}" # Append the unique identifier to the name
  }
}


