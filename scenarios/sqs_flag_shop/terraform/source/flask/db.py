import pymysql
import os

# PostgreSQL 연결 정보 설정
conn = pymysql.connect(
    db="cash",
    user="admin",
    passwd="bob12cgv",
    host=os.environ.get("AWS_RDS").split(":")[0],
)
