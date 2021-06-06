import boto3
from os import environ

ecs = boto3.client('ecs', region_name='us-east-1')

CLUSTER = environ['CLUSTER']
TASKDEF = environ['TASKDEF']
WEBSITE = environ['WEBSITE']

# print(ecs.list_tasks(cluster=CLUSTER))

task_waiter = ecs.get_waiter('tasks_running')

try:

    task_waiter.wait(cluster=CLUSTER, tasks=[WEBSITE])

except Exception as err:
    print(f"The website did not enter a stable state: {err}")

print("Website Task is running...")


instances = ecs.list_container_instances(cluster=CLUSTER)


for instanceArn in instances.get('containerInstanceArns'):
    data = ecs.describe_container_instances(cluster=CLUSTER, containerInstances=[instanceArn])
    data = data['containerInstances']
    container_count = data[0].get('runningTasksCount')

    if container_count <= 1:
        print(f"Deploying vault container to {instanceArn}")
        ecs.start_task(cluster=CLUSTER, containerInstances=[instanceArn], taskDefinition=TASKDEF)
        exit(0)


print("Failed to find instance to place vault container.")