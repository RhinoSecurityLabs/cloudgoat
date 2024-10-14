# Using CloudTrail for GuardDuty
resource "aws_cloudtrail" "cloudtrail" {
  name           = "cg-cloudtrail-${var.cgid}"
  s3_bucket_name = aws_s3_bucket.cloudtrail_bucket.id
  enable_logging = true

  depends_on = [aws_s3_bucket_policy.trail_bucket_policy]
}