

resource "aws_iam_role_policy_attachment" "cg-lambda-policy" {
  role       = "${aws_iam_role.cg-lambda-role.name}"
  policy_arn = "arn:aws:iam::aws:policy/AWSLambdaExecute"
}

resource "aws_iam_role_policy_attachment" "cg-lambda-policy2" {
  role       = "${aws_iam_role.cg-lambda-role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "cg-lambda-policy3" {
  role       = "${aws_iam_role.cg-lambda-role.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticFileSystemClientReadWriteAccess"
}


# A lambda function connected to an EFS file system
resource "aws_lambda_function" "efs_upload" {

  filename      = "../assets/efs_upload.zip"
  function_name = "cg-efs_upload-${var.cgid}"
  role          = "${aws_iam_role.cg-lambda-role.arn}"
  handler       = "lambda_function.lambda_handler"
  source_code_hash = "${filebase64sha256("../assets/efs_upload.zip")}"
  runtime = "python3.8"

  file_system_config {
    # EFS file system access point ARN
    arn = "${aws_efs_access_point.admin_access_point.arn}"
    # Local mount path inside the lambda function. Must start with '/mnt/'.
    local_mount_path = "/mnt/admin"
  }

  vpc_config {
    # Every subnet should be able to reach an EFS mount target in the same Availability Zone. Cross-AZ mounts are not permitted.
    subnet_ids         = ["${aws_subnet.cg-public-subnet-1.id}"]
    security_group_ids = ["${aws_security_group.cg-ec2-efs-security-group.id}"]
  }

  # Explicitly declare dependency on EFS mount target. 
  # When creating or updating Lambda functions, mount target must be in 'available' lifecycle state.
  depends_on = [aws_efs_mount_target.alpha, aws_efs_access_point.admin_access_point]
}


# Invoke the lambda function
data "aws_lambda_invocation" "efs_upload_invoke" {
  
  depends_on = [aws_lambda_function.efs_upload, aws_efs_access_point.admin_access_point]
  function_name = "${aws_lambda_function.efs_upload.function_name}"

  input = <<JSON
{
  "fname": "flag.txt",
  "text": "RmxhZzoge3todHRwczovL3lvdXR1LmJlL2RRdzR3OVdnWGNRfX0="
}
JSON
}

# output "flag" {
#   description = "String result of Lambda execution"
#   value       = "${data.aws_lambda_invocation.efs_upload_invoke.result}"
# }


