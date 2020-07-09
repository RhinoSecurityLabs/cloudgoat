resource "aws_efs_file_system" "admin-backup" {
  tags = {
    Name = "cg-admin-backup-${var.cgid}"
  }
}


resource "aws_efs_mount_target" "alpha" {
  file_system_id = "${aws_efs_file_system.admin-backup.id}"
  subnet_id      = "${aws_subnet.cg-public-subnet-1.id}"
  security_groups = ["${aws_security_group.cg-ec2-efs-security-group.id}"]
}

