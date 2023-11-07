resource "aws_glue_connection" "test_connections" {
name = "test-connections"

connection_properties = {
JDBC_CONNECTION_URL = "jdbc:postgresql://database-1:5432/data"
USERNAME = "postgres"
PASSWORD = "bob12cgv"
JDBC_ENFORCE_SSL = "true"
}

connection_type = "AMAZON_RDS"

match_criteria = ["criteria"]

physical_connection_requirements {
availability_zone      = "us-west-2a"
security_group_id_list = [data.aws_security_group.selected.id]
subnet_id              = tolist(data.aws_subnet_ids.selected.ids)[0]
}
}