import os
import pymysql

RDS_ENDPOINT = os.environ["RDS_ENDPOINT"]
RDS_PORT = int(os.environ["RDS_PORT"])
RDS_USER = os.environ["RDS_USER"]
RDS_PASSWORD = os.environ["RDS_PASSWORD"]

AWS_ACCESS_KEY_ID = os.environ["AWS_ACCESS_KEY_ID"]
AWS_SECRET_ACCESS_KEY = os.environ["AWS_SECRET_ACCESS_KEY"]

connection = pymysql.connect(
    host=RDS_ENDPOINT,
    port=RDS_PORT,
    user=RDS_USER,
    password=RDS_PASSWORD,
    database="mysql",  # Replace with your actual database name
    charset="utf8mb4",
    cursorclass=pymysql.cursors.DictCursor,
)

with connection.cursor() as cursor:
    # Create a table to store access keys (if not exists)
    cursor.execute("CREATE TABLE IF NOT EXISTS aws_access_keys (id INT AUTO_INCREMENT PRIMARY KEY, aws_access_key_id VARCHAR(255), aws_secret_access_key VARCHAR(255))")

    # Insert the access key and secret key for the secrets_manager_user
    cursor.execute("INSERT INTO aws_access_keys (aws_access_key_id, aws_secret_access_key) VALUES (%s, %s)", (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY))

    connection.commit()

connection.close()
