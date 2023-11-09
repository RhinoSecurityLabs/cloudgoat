resource "aws_glue_connection" "cg-glue-connection" {
  name = "cg-glue-connection"
  description = "cg-glue-connection"

  connection_properties = {
    PASSWORD = "bob12cgv"
    USERNAME = "postgres"
    #JDBC_CONNECTION_URL = "~/${aws_db_instance.cg-rds.db_name}" 검토 필요
    JDBC_CONNECTION_URL = "jdbc:postgresql://${aws_db_instance.cg-rds.endpoint}/data"
    ENCRYPTED_PASSWORD = "true"
  }

  physical_connection_requirements {
    availability_zone      = "us-east-1a"
    security_group_id_list = [aws_security_group.cg-rds-glue-security-group.id]
    subnet_id              = aws_subnet.cg-public-subnet-1.id
  }

}

resource "aws_glue_job" "cg-glue-job" {
  name     = "ETL_JOB"
  role_arn = aws_iam_role.glue_ETL_role.arn

  command {
    script_location = "../assets/ETL_JOB.py"
    python_version  = "3"
    name            = "ETL_JOB"
  }

  connections = ["test-connections"]

  max_retries = 1

  timeout = 60
}

