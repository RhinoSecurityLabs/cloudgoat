import psycopg2
import os

# PostgreSQL 연결 정보 설정
conn = psycopg2.connect(
    dbname="bob12cgvdb",
    user="postgres",
    password="bob12cgv",
    host=os.environ.get("AWS_RDS").split(":")[0],
    port=5432,
)
