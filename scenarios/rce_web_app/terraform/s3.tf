#Logs S3 Bucket Policy
resource "aws_s3_bucket_policy" "cg-logs-s3-bucket-policy" {
  bucket = "${aws_s3_bucket.cg-logs-s3-bucket.id}"
  policy = <<POLICY
{
  "Id": "Policy1558803362844",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt1558803360562",
      "Action": [
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.cg-logs-s3-bucket.arn}/cg-lb-logs/AWSLogs/${data.aws_caller_identity.aws-account-id.account_id}/*",
      "Principal": {
        "AWS": [
          "127311923021"
        ]
      }
    }
  ]
}
POLICY
}
#Logs S3 Bucket
resource "aws_s3_bucket" "cg-logs-s3-bucket" {
  bucket = "cg-logs-s3-bucket-${var.cgid}"
  acl = "private"
  force_destroy = true
  tags = {
      Name = "cg-logs-s3-bucket-${var.cgid}"
      Description = "CloudGoat ${var.cgid} S3 Bucket used for ALB Logs"
      Stack = "${var.stack-name}"
      Scenario = "${var.scenario-name}"
  }
}
#Secret S3 Bucket
resource "aws_s3_bucket" "cg-secret-s3-bucket" {
  bucket = "cg-secret-s3-bucket-${var.cgid}"
  acl = "private"
  force_destroy = true
  tags = {
      Name = "cg-secret-s3-bucket-${var.cgid}"
      Description = "CloudGoat ${var.cgid} S3 Bucket used for storing a secret"
      Stack = "${var.stack-name}"
      Scenario = "${var.scenario-name}"
  }
}
#Keystore S3 Bucket
resource "aws_s3_bucket" "cg-keystore-s3-bucket" {
  bucket = "cg-keystore-s3-bucket-${var.cgid}"
  acl = "private"
  force_destroy = true
  tags = {
    Name = "cg-keystore-s3-bucket-${var.cgid}"
    Description = "CloudGoat ${var.cgid} S3 Bucket used for storing ssh keys"
    Stack = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}

#S3 Bucket Objects
resource "aws_s3_bucket_object" "cg-lb-log-file" {
  bucket = "${aws_s3_bucket.cg-logs-s3-bucket.id}"
  key = "cg-lb-logs/AWSLogs/${data.aws_caller_identity.aws-account-id.account_id}/elasticloadbalancing/${var.region}/2019/06/19/555555555555_elasticloadbalancing_us-east-1_app.cg-lb-cgidp347lhz47g.d36d4f13b73c2fe7_20190618T2140Z_10.10.10.100_5m9btchz.log"
  source = "../assets/555555555555_elasticloadbalancing_us-east-1_app.cg-lb-cgidp347lhz47g.d36d4f13b73c2fe7_20190618T2140Z_10.10.10.100_5m9btchz.log"
  tags = {
    Name = "cg-lb-log-file-${var.cgid}"
    Stack = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}
resource "aws_s3_bucket_object" "cg-db-credentials-file" {
  bucket = "${aws_s3_bucket.cg-secret-s3-bucket.id}"
  key = "db.txt"
  source = "../assets/db.txt"
  tags = {
    Name = "cg-db-credentials-file-${var.cgid}"
    Stack = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}
resource "aws_s3_bucket_object" "cg-ssh-private-key-file" {
  bucket = "${aws_s3_bucket.cg-keystore-s3-bucket.id}"
  key = "cloudgoat"
  source = "${var.ssh-private-key-for-ec2}"
  tags = {
    Name = "cg-ssh-private-key-file-${var.cgid}"
    Stack = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}
resource "aws_s3_bucket_object" "cg-ssh-public-key-file" {
  bucket = "${aws_s3_bucket.cg-keystore-s3-bucket.id}"
  key = "cloudgoat.pub"
  source = "${var.ssh-public-key-for-ec2}"
  tags = {
    Name = "cg-ssh-public-key-file-${var.cgid}"
    Stack = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}