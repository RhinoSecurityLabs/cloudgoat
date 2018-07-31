#resource "aws_iam_role" "glue_dev_endpoint" {
#  name = "glue_dev_endpoint"

#  assume_role_policy = <<EOF
#{
#  "Version": "2012-10-17",
#  "Statement": [
#    {
#      "Action": "sts:AssumeRole",
#      "Principal": {
#        "Service": "glue.amazonaws.com"
#      },
#      "Effect": "Allow",
#      "Sid": ""
#    }
#  ]
#}
#EOF
#}

#resource "aws_iam_role_policy" "glue_iam_policy" {
#  name = "policy_for_glue_role"
#  role = "${aws_iam_role.glue_dev_endpoint.id}"

#  policy = <<EOF
#{
#  "Version": "2012-10-17",
#  "Statement": [
#    {
#      "Action": [
#        "glue:*",
#        "rds:*",
#        "dynamodb:*"
#      ],
#      "Effect": "Allow",
#      "Resource": "*"
#    }
#  ]
#}
#EOF
#}
