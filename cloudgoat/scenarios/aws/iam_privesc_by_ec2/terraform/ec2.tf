resource "aws_instance" "admin_ec2" {
  ami                  = data.aws_ami.ec2.id
  instance_type        = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.ec2_role.name

  # Specify the VPC's private subnet
  subnet_id = aws_subnet.private_subnet.id

  # Tags for the instance
  tags = {
    Name = "cg_admin_ec2_${var.cgid}" # Append the unique identifier to the name
  }
}
