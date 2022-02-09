#IAM User
resource "aws_iam_user" "r_waterhouse" {
  name = "cg-r_waterhouse-${var.cgid}"
  provisioner "local-exec" {
    when    = destroy
    command = "./resource_cleaning.sh ${self.name}"
  }
}

resource "aws_iam_access_key" "r_waterhouse" {
  user = aws_iam_user.r_waterhouse.name
}

//add randy to a dev group
resource "aws_iam_group" "developers" {
  name = "developers"
  path = "/developers/"
}





// the below policy should grant ec2 permissions to the user
// resource "aws_iam_user_policy" "ec2_access" {
//   name = "${aws_iam_user.r_waterhouse.name}-ec2-access"
//   user = aws_iam_user.r_waterhouse.name

//   policy = <<EOF
// {
//     "Version": "2012-10-17",
//     "Statement": [
//         {
//             "Sid": "",
//             "Effect": "Allow",
//             "Action": "sts:AssumeRole",
//             "Resource": "arn:aws:iam::940877411605:role/cg-lambda-invoker*"
//         }
//     ]
// }
// EOF
// }
