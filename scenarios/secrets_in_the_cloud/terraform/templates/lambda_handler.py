import os
import json


def lambda_handler(event, context):
    api_key = os.environ['API_KEY']
    return {'statusCode': 200, 'body': json.dumps({'api_key': api_key})}
