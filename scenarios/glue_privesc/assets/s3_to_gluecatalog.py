import boto3
import os


def add_header_to_csv_file(input_bucket, input_key):
    s3 = boto3.client("s3")

    # 원본 파일 다운로드
    response = s3.get_object(Bucket=input_bucket, Key=input_key)
    content = response["Body"].read().decode("utf-8")

    header = content.split("\r\n")[0]

    if header == "order_date,item_id,price,country_code":
        output_bucket = os.environ["BUCKET_Final"]
        output_key = "result.csv"
        s3.put_object(Bucket=output_bucket, Key=output_key, Body=content)

        return [output_bucket, output_key]

    else:
        # 헤더 추가
        header = "order_date,item_id,price,country_code"
        content_with_header = header + "\r\n" + content

        output_bucket = os.environ["BUCKET_Final"]
        output_key = "result.csv"
        s3.put_object(Bucket=output_bucket, Key=output_key, Body=content_with_header)

        return [output_bucket, output_key]


def lambda_handler(event, context):
    glue = boto3.client("glue")
    job_name = "ETL_JOB"  # 실행할 Glue Job의 이름으로 변경
    s3_bucket = os.environ["BUCKET_Scenario2"]
    s3_object_key = event["Records"][0]["s3"]["object"]["key"]

    # 파일 확장자 표시
    file_format = s3_object_key.split(".")[-1]

    if file_format == "csv":
        output_bucket, output_key = add_header_to_csv_file(s3_bucket, s3_object_key)

        response = glue.start_job_run(
            JobName=job_name,
            Arguments={
                "--s3_source_path": f"s3://{output_bucket}/{output_key}",
                "--jdbc_url": os.environ["JDBC_URL"],
            },
        )
        return response

    else:
        return print("file_format is not csv")
