import json
import boto3
import os


def lambda_handler(event, context):
    print("Event:", event)

    # Get information from environment variables
    user_email = os.environ['USER_EMAIL']
    iam_role_1 = os.environ['IAM_ROLE_1']
    iam_role_2 = os.environ['IAM_ROLE_2']
    instance_profile_1 = os.environ['INSTANCE_PROFILE_1']
    instance_profile_2 = os.environ['INSTANCE_PROFILE_2']
    detector_id = os.environ['GUARDDUTY_DETECTOR_ID']
    account_id = os.environ['ACCOUNT_ID']

    # Extract the EC2 instance ID and the current assigned role name from the event
    instance_id = event['detail']['resource']['instanceDetails']['instanceId']
    current_role_name = event['detail']['resource']['accessKeyDetails']['userName']

    # Create boto3 clients
    iam = boto3.client('iam')
    ec2_client = boto3.client('ec2')
    ses = boto3.client('ses')
    guardduty = boto3.client('guardduty')

    # Determine the new role to be assigned
    if current_role_name == iam_role_1:
        new_role = iam_role_2
        new_profile = instance_profile_2
        old_role = iam_role_1
    elif current_role_name == iam_role_2:
        new_role = iam_role_1
        new_profile = instance_profile_1
        old_role = iam_role_2
    else:
        print("Current role does not match any in the env variables.")
        return

    try:
        # Copy IAM policies
        copy_role_policies(iam, old_role, new_role)

        # Change the role
        response = ec2_client.replace_iam_instance_profile_association(
            IamInstanceProfile={
                'Arn': f'arn:aws:iam::{account_id}:instance-profile/{new_profile}',
                'Name': new_role
            },
            AssociationId=get_association_id(ec2_client, instance_id)
        )
        print("Role has been successfully changed.\n" + str(response))

        # Detach policies from the old role
        detach_role_policies(iam, old_role)
    except Exception as e:
        print("Error occurred while changing the role.\n" + str(e))
        return

    # Send an email
    subject = "GuardDuty Alert: Unauthorized Access"
    body_text = "GuardDuty has detected unauthorized access. \n\n" + json.dumps(event, indent=4)
    ses.send_email(
        Source=user_email,
        Destination={'ToAddresses': [user_email]},
        Message={
            'Subject': {'Data': subject},
            'Body': {'Text': {'Data': body_text}}
        }
    )
    print("Email sent successfully.")

    # Update the status of Findings
    try:
        # Dynamically retrieve findings
        findings = guardduty.list_findings(DetectorId=detector_id, MaxResults=10)
        findings_ids = findings.get('FindingIds', [])

        print("Findings: " + str(findings))
        print("Findings IDs: " + str(findings_ids))

        # Update the status of findings that meet the condition
        if findings_ids:
            guardduty.update_findings_feedback(
                DetectorId=detector_id,
                FindingIds=findings_ids,
                Feedback='USEFUL'
            )
        print("Findings status successfully updated.")
    except Exception as e:
        print("Failed to update findings status:", str(e))

    return {
        'statusCode': 200,
        'body': 'Processed successfully!'
    }


def get_association_id(ec2_client, instance_id):
    # Function to get the current IAM instance profile association ID for the instance
    response = ec2_client.describe_iam_instance_profile_associations(
        Filters=[{'Name': 'instance-id', 'Values': [instance_id]}])
    associations = response.get('IamInstanceProfileAssociations', [])
    for association in associations:
        if association['State'] in ['associated', 'associating']:
            return association['AssociationId']
    return None


def copy_role_policies(iam, source_role, destination_role):
    # Copy managed policies
    managed_policies = iam.list_attached_role_policies(RoleName=source_role)['AttachedPolicies']
    for policy in managed_policies:
        iam.attach_role_policy(
            RoleName=destination_role,
            PolicyArn=policy['PolicyArn']
        )

    # Copy inline policies
    inline_policies = iam.list_role_policies(RoleName=source_role)['PolicyNames']
    for policy_name in inline_policies:
        policy_document = iam.get_role_policy(RoleName=source_role, PolicyName=policy_name)['PolicyDocument']
        iam.put_role_policy(
            RoleName=destination_role,
            PolicyName=policy_name,
            PolicyDocument=json.dumps(policy_document)
        )

    print(f"Policies from {source_role} have been copied to {destination_role}.")


def detach_role_policies(iam, role_name):
    # Detach managed policies
    managed_policies = iam.list_attached_role_policies(RoleName=role_name)['AttachedPolicies']
    for policy in managed_policies:
        iam.detach_role_policy(
            RoleName=role_name,
            PolicyArn=policy['PolicyArn']
        )

    # Remove inline policies
    inline_policies = iam.list_role_policies(RoleName=role_name)['PolicyNames']
    for policy_name in inline_policies:
        iam.delete_role_policy(
            RoleName=role_name,
            PolicyName=policy_name
        )

    print(f"All policies have been detached from {role_name}.")
