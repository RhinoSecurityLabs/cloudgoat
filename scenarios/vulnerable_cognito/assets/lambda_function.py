import json
import boto3
client = boto3.client('cognito-idp')


def lambda_handler(event, context):

	UserPoolid=event['userPoolId']
	
	UserName = event['request']['userAttributes']['sub']

	print(event)

	client.admin_update_user_attributes(UserPoolId=UserPoolid,Username=UserName,UserAttributes=[{'Name':'custom:access','Value':'reader'}])

	return event