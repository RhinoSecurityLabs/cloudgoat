import boto3
from os import environ

import time
timeout = time.time() + 60*5   # 5 minutes from now

ecs = boto3.client('ecs', region_name='us-east-1')

# CLUSTER = environ['CLUSTER']

CLUSTER= 'my-cluster'


def findTaskInstance(taskid):
    try:
        res = ecs.describe_tasks(cluster=CLUSTER, tasks=[taskid])
        if res.get('tasks'):
            return res['tasks'][0]['containerInstanceArn']
    except:
        return None


def findTaskId(serviceName):
    try:
        res = ecs.list_tasks(cluster=CLUSTER, serviceName=serviceName)
        for taskid in res.get('taskArns'):
            return taskid
    except:
        return None


while True:

    vulnsiteInstance = findTaskInstance(findTaskId('vulnsite'))
    vaultInstance = findTaskInstance(findTaskId('vault'))

    if (not vulnsiteInstance or not vaultInstance) :
        print("Could not find containers...waiting 5 seconds")
        time.sleep(5)
    
    elif time.time() > timeout:
        print("Failed to reach configuration after 5 minutes....exiting")
        break

    elif(vulnsiteInstance == vaultInstance):
        print("Container are on same host...stopping vault container")
        ecs.stop_task(cluster=CLUSTER, task=findTaskId('vault'))
        print("waiting 15 seconds...")
        time.sleep(15)
        vulnsiteInstance = findTaskInstance(findTaskId('vulnsite'))
        vaultInstance = findTaskInstance(findTaskId('vault'))
        
    elif vaultInstance != vulnsiteInstance:
        print("Container configuration reached")
        print("state: " + str(vaultInstance) + ", " + str(vulnsiteInstance))
        break

    else:
        print("Unknown state: " + str(vaultInstance) + ", " + str(vulnsiteInstance))



