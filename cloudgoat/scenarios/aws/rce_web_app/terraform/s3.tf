#Logs S3 Bucket
resource "aws_s3_bucket" "logs" {
  bucket        = "cg-logs-s3-bucket-${local.cgid_suffix}"
  force_destroy = true
  tags = {
    Description = "CloudGoat ${var.cgid} S3 Bucket used for ALB Logs"
  }
}

#Logs S3 Bucket Policy
resource "aws_s3_bucket_policy" "logs_policy" {
  bucket = aws_s3_bucket.logs.id
  policy = jsonencode({
    Id      = "Policy1558803362844"
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "load-balancer-policy"
        Action   = "s3:PutObject"
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.logs.arn}/cg-lb-logs/AWSLogs/${data.aws_caller_identity.this.account_id}/*"
        Principal = {
          AWS = "arn:aws:iam::127311923021:root"
        }
      }
    ]
  })
}

resource "aws_s3_object" "lb_logs" {
  bucket = aws_s3_bucket.logs.id
  key    = "cg-lb-logs/AWSLogs/${data.aws_caller_identity.this.account_id}/elasticloadbalancing/${var.region}/2019/06/19/555555555555_elasticloadbalancing_us-east-1_app.cg-lb-cgidp347lhz47g.d36d4f13b73c2fe7_20190618T2140Z_10.10.10.100_5m9btchz.log"
  content = templatefile("../assets/elasticloadbalancing.log", {
    cgid              = "cg-lb-${local.cgid_suffix}"
    load_balancer_dns = aws_lb.this.dns_name
    target_group_arn  = aws_lb_target_group.this.arn
  })
}


#Secret S3 Bucket
resource "aws_s3_bucket" "secret" {
  bucket        = "cg-secret-s3-bucket-${local.cgid_suffix}"
  force_destroy = true
  tags = {
    Description = "CloudGoat ${var.cgid} S3 Bucket used for storing a secret"
  }
}

resource "aws_s3_object" "db_credentials" {
  bucket = aws_s3_bucket.secret.id
  key    = "db.txt"
  source = "../assets/db.txt"
}


#Keystore S3 Bucket
resource "aws_s3_bucket" "keystore" {
  bucket        = "cg-keystore-s3-bucket-${local.cgid_suffix}"
  force_destroy = true
  tags = {
    Description = "CloudGoat ${var.cgid} S3 Bucket used for storing ssh keys"
  }
}

resource "aws_s3_object" "ssh_private_key" {
  bucket = aws_s3_bucket.keystore.id
  key    = "cloudgoat"
  source = var.ssh_private_key
}

resource "aws_s3_object" "ssh_public_key" {
  bucket = aws_s3_bucket.keystore.id
  key    = "cloudgoat.pub"
  source = var.ssh_public_key
}
