#AWS Account Id
data "aws_caller_identity" "aws-account-id" {
  
}
#S3 Full Access Policy
data "aws_iam_policy" "s3-full-access" {
  arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}