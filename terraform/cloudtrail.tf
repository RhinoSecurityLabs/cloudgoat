resource "aws_cloudtrail" "cloudgoat_record" {
  name                          = "cloudgoat_trail"
  s3_bucket_name                = "${aws_s3_bucket.cloudgoat_private.id}"
  s3_key_prefix                 = "cloudtrail"
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
}

