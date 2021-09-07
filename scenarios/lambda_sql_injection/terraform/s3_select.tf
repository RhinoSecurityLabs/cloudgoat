# resource "aws_db_instance" "lambda_backend" {
#   allocated_storage    = 20
#   engine               = "mysql"
#   engine_version       = "5.7"
#   instance_class       = "db.t3.micro"
#   name                 = "lambda_backend"
#   username             = "cg_admin"
#   password             = "${var.cgid}"
#   publicly_accessible  = true
#   parameter_group_name = "default.mysql5.7"
#   skip_final_snapshot  = true
#   tags = {
#     Name     = "cg-${var.cgid}"
#     Stack    = "${var.stack-name}"
#     Scenario = "${var.scenario-name}"
#   }
# }

# s3 buckets and csv objects instead?
resource "aws_s3_bucket" "my_database_bucket" {
  bucket = "cg-${var.profile}-db"
  acl    = "private"
  tags = {
    Name     = "cg-${var.cgid}"
    Stack    = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}

resource "aws_s3_bucket_object" "csv_database" {
  bucket = "${aws_s3_bucket.my_database_bucket.bucket}"
  key    = "cg-${var.cgid}-csv-database"
  source = "./database.csv"

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  etag = filemd5("./database.csv")
}











