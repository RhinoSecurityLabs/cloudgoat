#Null Resources
resource "null_resource" "cg-create-latest-passwords-list-file" {
  provisioner "local-exec" {
      command = "touch ../assets/latest-passwords-list.txt"
  }
}
resource "null_resource" "cg-create-sheperds-credentials-file" {
  provisioner "local-exec" {
      command = "touch ../assets/admin-user.txt && echo ${aws_iam_access_key.cg-shepard.id} >>../assets/admin-user.txt && echo ${aws_iam_access_key.cg-shepard.secret} >>../assets/admin-user.txt"
  }
}