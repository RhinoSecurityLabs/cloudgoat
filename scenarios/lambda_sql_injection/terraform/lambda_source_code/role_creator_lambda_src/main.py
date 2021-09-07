import boto3

iam_client = boto3.client('iam')
s3_client = boto3.client('s3')

def handler(event, context): 
    target_policy = event['managed_policy_name']
    user_name = event['user_name']
    
    response = s3_client.select_object_content(
        Bucket = "cg-default-db",
        Key = "cg-lambda_sql_injection_cgidacbik73htz-csv-database",
        Expression = f"SELECT * FROM s3object where policy_name='{target_policy}'",
        ExpressionType = 'SQL' ,
        InputSerialization = {'CSV': {"FileHeaderInfo": "Use"}, 'CompressionType': 'NONE'},
        OutputSerialization =  {"CSV": {}}
        )
   
    results = ""
    for each in response["Payload"]:
        if 'Records' in each:
            results = each["Records"]['Payload'].decode('utf-8')
            print(results)
        
        # results = results + str(each)
    
    
     # response = iam_client.attach_user_policy(
    #     UserName= user_name,
    #     PolicyArn=f"arn:aws:iam::aws:policy/{target_policy}"
    #     )
    
    return results
    
    
if __name__ == "__main__":
    print(handler('policy_arn','invalid:arn:string'))