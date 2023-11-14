resource "aws_glue_connection" "cg-glue-connection" {
  name        = "cg-glue-connection"
  description = "This Glue Connection is used to connect to the RDS database."

  connection_type = "JDBC"

  connection_properties = {
    PASSWORD            = "bob12cgv"
    USERNAME            = "postgres"
    JDBC_CONNECTION_URL = "jdbc:postgresql://${aws_db_instance.cg-rds.endpoint}/${var.rds-database-name}"
  }

  physical_connection_requirements {
    availability_zone      = "us-east-1a"
    security_group_id_list = [aws_security_group.cg-rds-glue-security-group.id]
    subnet_id              = aws_subnet.cg-public-subnet-1.id
  }
}

#암호화 비활성화 추가
resource "aws_glue_data_catalog_encryption_settings" "example" {
  data_catalog_encryption_settings {
    connection_password_encryption {
      return_connection_password_encrypted = false
    }

    encryption_at_rest {
      catalog_encryption_mode = "DISABLED"
    }
  }
}


resource "aws_glue_job" "cg-glue-job" {
  name     = "ETL_JOB"
  role_arn = aws_iam_role.glue_ETL_role.arn

  command {
    script_location = "s3://${aws_s3_bucket.cg-data-s3-bucket.bucket}/${aws_s3_object.glue_script_file.key}"
    python_version  = "3"
    name            = "ETL_JOB"
  }

  connections = [aws_glue_connection.cg-glue-connection.name] # 위에서 정의한 Glue 연결 사용

  max_retries = 3

  timeout = 60
}

resource "aws_s3_object" "glue_script_file" {
  bucket = aws_s3_bucket.cg-data-s3-bucket.id
  key    = "glue_ETL_JOB"
  source = "../assets/ETL_JOB.py"
}
