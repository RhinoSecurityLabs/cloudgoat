resource "aws_cloudtrail" "cloudgoat_record" {
  name                          = "tf-trail-foobar"
  s3_bucket_name                = "${aws_s3_bucket.cloudgoat.id}"
  s3_key_prefix                 = "cloudtrail"
  include_global_service_events = true
}

resource "aws_s3_bucket" "cloudgoat" {
  bucket        = "${var.cloudgoat_bucket_name}"
  force_destroy = true

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
            "Resource": "arn:aws:s3:::tf-test-trail"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::tf-test-trail/*",
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

variable "cloudgoat_bucket_name" {
  type = "string"
  default = ""
}
