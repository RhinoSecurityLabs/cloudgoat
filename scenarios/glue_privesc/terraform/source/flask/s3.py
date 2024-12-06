import boto3
import os

# AWS S3 설정
AWS_ACCESS_KEY_ID = os.environ.get("AWS_ACCESS_KEY_ID")
AWS_SECRET_ACCESS_KEY = os.environ.get("AWS_SECRET_ACCESS_KEY")
AWS_REGION = os.environ.get("AWS_REGION")
AWS_BUCKET_NAME = os.environ.get("AWS_S3_BUCKET")

s3 = boto3.client("s3")
