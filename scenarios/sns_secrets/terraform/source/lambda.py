import os
import boto3
import json

sns_client = boto3.client("sns")

def handler(event, context):
    api_gateway_key = os.getenv("API_GATEWAY_KEY", "No API Gateway Key found")
    sns_topic_arn = os.getenv("SNS_ARN", "No SNS Topic ARN found")

    message = {
        "default": f"DEBUG: API GATEWAY KEY {api_gateway_key}"
    }

    try:
        # Publish message to SNS topic
        response = sns_client.publish(
            Message = json.dumps(message),
            MessageStructure = "json",
            TopicArn = sns_topic_arn
        )

        # Log success and return response
        return {
            "statusCode": 200,
            "body": json.dumps(
                {
                    "message": "Message sent successfully!",
                    "response": response
                }
            )
        }

    except Exception as e:
        # Log the exception and return error response
        return {
            "statusCode": 500,
            "body": json.dumps(
                {
                    "message": "Failed to send message",
                    "error": str(e)
                }
            )
        }
