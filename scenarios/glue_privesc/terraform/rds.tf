resource "aws_db_instance" "cg-rds" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "13.7"
  instance_class       = "db.t3.micro"
  db_subnet_group_name = aws_db_subnet_group.cg-rds-subnet-group.id
  db_name              = var.rds-database-name
  username             = var.rds_username
  password             = var.rds_password
  parameter_group_name = "default.postgres13"
  publicly_accessible  = false
  skip_final_snapshot  = true

  port = "5432"

  storage_encrypted = true

  vpc_security_group_ids = [
    aws_security_group.cg-rds-security-group.id,
  ]

  depends_on = [local_file.sql_file]
  tags = {
    Name     = "cg-rds-instance-${var.cgid}"
    Stack    = var.stack-name
    Scenario = var.scenario-name
  }
}

data "local_file" "csv_file" {
  filename = "../assets/order_data2.csv"
}

#data "template_file" "sql_template" {
#  template = <<-EOT
#
#    CREATE TABLE original_data (
#        order_date VARCHAR(255),
#        item_id VARCHAR(255),
#        price numeric(10,2),
#        country_code VARCHAR(50)
#    );
#
#    CREATE TABLE cc_data (
#        country_code VARCHAR(50),
#        purchase_cnt int,
#        avg_price numeric(10,2)
#    );
#
#    %{for row in csvdecode(data.local_file.csv_file.content)}
#            INSERT INTO original_data (order_date, item_id, price, country_code) VALUES ('${row.order_date}', '${row.item_id}', ${format("%.2f", row.price)}, '${row.country_code}');
#    %{endfor}
#
#    INSERT INTO original_data (order_date, item_id, price, country_code) VALUES ('${var.rds_user_key}', '${var.rds_user_secret}', DEFAULT, DEFAULT);
#  EOT
#}


data "template_file" "sql_template" {
  template = templatefile("${path.module}/../assets/sql_template.tpl", {
    csv_content = data.local_file.csv_file.content,
    aws_access_key_id = aws_iam_access_key.cg-glue-admin_access_key.id,
    aws_secret_access_key = aws_iam_access_key.cg-glue-admin_access_key.secret
  })
}


resource "local_file" "sql_file" {
  content  = data.template_file.sql_template.rendered
  filename = "../assets/insert_data.sql"
}



resource "aws_db_subnet_group" "cg-rds-subnet-group" {
  name = "cg-rds-subnet-group-${var.cgid}"
  subnet_ids = [
    aws_subnet.cg-private-subnet-1.id,
    aws_subnet.cg-private-subnet-2.id
  ]
  description = "CloudGoat ${var.cgid} Subnet Group"
  tags = {
    Name     = "cloud-goat-rds-subnet-group-${var.cgid}"
    Stack    = var.stack-name
    Scenario = var.scenario-name
  }
}