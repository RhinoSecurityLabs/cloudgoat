import boto3
import os

aws_access_key_id = os.environ.get("AWS_ACCESS_KEY_ID")
aws_secret_access_key = os.environ.get("AWS_SECRET_ACCESS_KEY")
aws_region_name = "us-east-1"

sqs_queue_url = os.environ.get("AWS_SQS_URL")

sqs_client = boto3.client(
    "sqs",
    region_name=aws_region_name,
    aws_access_key_id=aws_access_key_id,
    aws_secret_access_key=aws_secret_access_key,
)
