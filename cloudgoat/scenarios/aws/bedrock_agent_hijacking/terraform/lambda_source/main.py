import json
import boto3

MAX_ITEMS = 100

iam_client = boto3.client('iam')
s3_client = boto3.client('s3')
ec2_client = boto3.client('ec2')


def inventory_iam_roles():
    roles = []
    paginator = iam_client.get_paginator('list_roles')
    for page in paginator.paginate(PaginationConfig={'MaxItems': MAX_ITEMS}):
        for r in page.get('Roles', []):
            roles.append({
                'roleName': r['RoleName'],
                'arn': r['Arn'],
                'path': r['Path']
            })
    return {'iamRoles': roles}


def inventory_iam_users():
    users = []
    paginator = iam_client.get_paginator('list_users')
    for page in paginator.paginate(PaginationConfig={'MaxItems': MAX_ITEMS}):
        for u in page.get('Users', []):
            users.append({
                'roleName': u['UserName'],
                'arn': u['Arn'],
                'path': u['Path']
            })
    return {'iamUsers': users}


def inventory_ec2_instances():
    instances = []
    paginator = ec2_client.get_paginator('describe_instances')
    for page in paginator.paginate(PaginationConfig={'MaxItems': MAX_ITEMS}):
        for reservation in page.get('Reservations', []):
            for inst in reservation.get('Instances', []):
                ni_list = []
                for ni in inst.get('NetworkInterfaces', []):
                    ni_list.append({
                        'networkInterfaceId': ni['NetworkInterfaceId'],
                        'privateIpAddress': ni['PrivateIpAddress'],
                        'subnetId': ni['SubnetId'],
                        'vpcId': ni['VpcId'],
                        'status': ni['Status']
                    })

                instances.append({
                    'instanceId': inst['InstanceId'],
                    'instanceType': inst['InstanceType'],
                    'state': inst['State']['Name'],
                    'vpcId': inst['VpcId'],
                    'subnetId': inst['SubnetId'],
                    'privateIpAddress': inst['PrivateIpAddress'],
                    'networkInterfaces': ni_list
                })
    return {"ec2Instances": instances}


def inventory_s3_buckets():
    buckets = []
    paginator = s3_client.get_paginator('list_buckets')
    for page in paginator.paginate(PaginationConfig={'MaxItems': MAX_ITEMS}):
        for buck in page.get('Buckets', []):
            buckets.append({
                'name': buck['Name'],
                'creationDate': buck['CreationDate'].isoformat()
            })
    return {'s3Buckets': buckets}


def inventory_all():
    result = {}
    result.update(inventory_iam_roles())
    result.update(inventory_s3_buckets())
    result.update(inventory_iam_users())
    result.update(inventory_ec2_instances())
    return result


# Map operation values → implementation functions
OPERATION_HANDLERS = {
    "LIST_IAM_ROLES": inventory_iam_roles,
    "LIST_IAM_USERS": inventory_iam_users,
    "LIST_EC2_INSTANCES": inventory_ec2_instances,
    "LIST_S3_BUCKETS": inventory_s3_buckets,
    "LIST_ALL": inventory_all,
}


def handler(event, context):
    """
    Expected event:
    {
      "operation": "LIST_IAM_ROLES"
        | "LIST_S3_BUCKETS"
        | "LIST_IAM_USERS"
        | "LIST_EC2_INSTANCES"
        | "LIST_ALL"
    }
    """
    operation = event['function']

    # Handle invalid operation
    target_function = OPERATION_HANDLERS.get(operation)
    if target_function is None:
        return format_response(
            event,
            json.dumps({
                'error': f'Unsupported function "{operation}"',
                'allowedFunctions': list(OPERATION_HANDLERS.keys())
            }),
            'REPROMPT'
        )

    # Process and return results
    try:
        result = target_function()
        return format_response(
            event,
            json.dumps(result)
        )
    except Exception as e:
        format_response(
            event,
            json.dumps({
                'error': 'Internal error while processing operation',
                'details': str(e)
            }),
            'FAILURE'
        )


def format_response(event, message, error=None):
    response = {
        'actionGroup': event['actionGroup'],
        'function': event['function'],
        'functionResponse': {
            'responseBody': {
                'TEXT': {
                    'body': message
                }
            }
        }
    }
    if error:
        response['functionResponse']['responseState'] = error
    return {
        "messageVersion": "1.0",
        "response": response
    }
