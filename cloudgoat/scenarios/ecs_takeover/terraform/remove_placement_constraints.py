"""Removes the PlacmentConstraints set for a given cluster/service."""
import boto3
import time
from os import environ

ecs = boto3.client('ecs', region_name='us-east-1')

cluster = environ['CLUSTER']
service_name = environ['SERVICE_NAME']

while True:
    resp = ecs.list_tasks(
        cluster=cluster,
        serviceName=service_name,
        desiredStatus="RUNNING",
    )
    if len(resp['taskArns']) > 0:
        break

    print(f"Waiting for tasks in the service {service_name} to enter the the RUNNING state.")
    time.sleep(5)

ecs.update_service(
    cluster=cluster,
    service=service_name,
    placementConstraints=[],
)