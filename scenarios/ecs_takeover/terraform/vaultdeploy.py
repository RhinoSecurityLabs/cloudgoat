import boto3
from os import environ

import time
timeout = time.time() + 60*5   # 5 minutes from now

ecs = boto3.client('ecs', region_name='us-east-1')

CLUSTER = environ['CLUSTER']
TASKDEF = environ['TASKDEF']
SERVICE = environ['SERVICE']

taskid = ""


# Find vulnsite taskid
while True:
    try:

        if time.time() > timeout:
            print("Vulnsite Taskid was not found after 5 mins...continuing.")
            break

        res = ecs.list_tasks(cluster=CLUSTER, serviceName=SERVICE)
        taskid= res['taskArns'][0]
        break

    except Exception as err:
        pass


print("Found Vulnsite TaskID...")

# Attempt to wait for the vulnsite task to be "RUNNING"
try:
    task_waiter = ecs.get_waiter('tasks_running')
    task_waiter.wait(cluster=CLUSTER, tasks=[taskid])

except Exception as err:
    print(f"The website did not enter a stable state: {err}")



print("Website Task is running...")

instances = ecs.list_container_instances(cluster=CLUSTER)


for instanceArn in instances.get('containerInstanceArns'):
    data = ecs.describe_container_instances(cluster=CLUSTER, containerInstances=[instanceArn])
    data = data['containerInstances']
    container_count = data[0].get('runningTasksCount')

    if container_count <= 1:
        ecs.start_task(cluster=CLUSTER, containerInstances=[instanceArn], taskDefinition=TASKDEF)
        print(f"Deploying vault container to {instanceArn}")
        exit(0)


print("Failed to find instance to place vault container.")