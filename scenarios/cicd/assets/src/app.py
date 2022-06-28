import sys
import json

def handle(event):
  body = event.get('body')
  if body is None:
    return 400, "missing body"

  if 'superSecretData=' not in body:
    return 400, "missing superSecretData"

  return 200, "OK" 

def handler(event, context):
  statusCode, responseBody = handle(event)
  return {
    "isBase64Encoded": False,
    "statusCode": statusCode,
    "headers": {},
    "multiValueHeaders": {},
    "body": json.dumps({'message': responseBody})
  }