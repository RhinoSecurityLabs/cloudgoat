

resource "aws_cloudtrail" "cloudgoat_trail" {
  name                          = "cloudgoat-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  s3_key_prefix                 = "prefix"
  include_global_service_events = true
}

resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket        = "tf-t"
  force_destroy = true

}

resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  policy = <<POLICY
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "AWSCloudTrailAclCheck",
                "Effect": "Allow",
                "Principal": {
                "Service": "cloudtrail.amazonaws.com"
                },
                "Action": "s3:GetBucketAcl",
                "Resource": "arn:aws:s3:::${aws_s3_bucket.cloudtrail_logs.bucket}"
            },
            {
                "Sid": "AWSCloudTrailWrite",
                "Effect": "Allow",
                "Principal": {
                "Service": "cloudtrail.amazonaws.com"
                },
                "Action": "s3:PutObject",
                "Resource": "arn:aws:s3:::${aws_s3_bucket.cloudtrail_logs.bucket}/prefix/AWSLogs/${data.aws_caller_identity.aws-account-id.account_id}/*",
                "Condition": {
                    "StringEquals": {
                        "s3:x-amz-acl": "bucket-owner-full-control"
                    }
                }
            }
        ]
    }
    POLICY
}

