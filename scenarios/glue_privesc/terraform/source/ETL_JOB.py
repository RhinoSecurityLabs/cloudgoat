# csv 데이터 rds 테이블에 저장하기

import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql import SparkSession

# AWS Glue 파라미터 설정
args = getResolvedOptions(sys.argv, ["JOB_NAME", "s3_source_path", "jdbc_url"])

# 인자로 받아오는 s3 path
s3_source_path = args["s3_source_path"]
jdbc_url = args["jdbc_url"]

# SparkContext 및 GlueContext 초기화
sc = SparkContext()
spark = SparkSession(sc)
glueContext = GlueContext(sc)

# AWS Glue 작업 초기화
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

# Glue DynamicFrame 생성
dynamicFrame = glueContext.create_dynamic_frame.from_options(
    connection_type="s3",
    connection_options={"paths": [s3_source_path]},
    format="csv",
    format_options={
        "withHeader": True,
    },
)

# 실수로 변환
dynamicFrame = dynamicFrame.resolveChoice(specs=[("price", "cast:double")])
# dynamicFrame = dynamicFrame.resolveChoice(specs=[("price", "cast:decimal(10,2)")])

print("dynamicFrame : ", dynamicFrame)

# DataFrame 가공하기
all_fields_selected = SelectFields.apply(
    frame=dynamicFrame, paths=["order_date", "item_id", "price", "country_code"]
)
print(all_fields_selected)

# DynamicFrame을 RDS(PostgreSQL)로 쓸 때 필요한 설정
connection_options = {
    "url": jdbc_url,
    "dbtable": "original_data",
    "user": "postgres",
    "password": "bob12cgv",
    "database": "bob12cgvdb",
}

connection_properties = {"user": "postgres", "password": "bob12cgv"}


# Glue DynamicFrame을 RDS(PostgreSQL)에 쓰기
result = glueContext.write_dynamic_frame.from_jdbc_conf(
    frame=all_fields_selected,
    catalog_connection="test-connections",  # Glue Data Catalog에 정의된 JDBC 연결 이름
    connection_options=connection_options,
)

print("result: ", result)

# 전체 데이터를 불러와서 가공하고 나라별 그룹화 한 데이터 저장
sql_query = "SELECT country_code, COUNT(*) AS purchase_cnt, ROUND(avg(price), 2) AS avg_price FROM original_data GROUP BY country_code"

result_dataframe = spark.read.jdbc(
    url=connection_options["url"],
    table="({}) AS subquery".format(sql_query),
    properties=connection_properties,
)
print(result_dataframe)

# 결과 DataFrame을 RDS PostgreSQL에 덮어씁니다.
try:
    result_dataframe.write.jdbc(
        url=connection_options["url"],
        table="cc_data",
        mode="append",
        properties=connection_properties,
    )
except Exception as e:
    print("Error while writing to PostgreSQL:", str(e))

# AWS Glue 작업 완료
job.commit()
spark.stop()  #
