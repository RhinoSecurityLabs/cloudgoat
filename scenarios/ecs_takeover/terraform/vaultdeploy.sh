
# This script guarenturess the flag container is deploy on a seperate instance from the website. 
#
#

# Wait for the website container to be running
aws ecs wait services-stable \
    --cluster $CLUSTERNAME \
    --services $WEBSITE

# Get list of instances in cluster
instances=$(aws ecs list-container-instances --cluster $CLUSTERNAME | jq -r '.containerInstanceArns[]')

for arn in $instances; do

    # Get container count on instance
    count=$(aws ecs describe-container-instances --cluster $CLUSTERNAME --container-instances "$arn" | jq ".containerInstances[0].runningTasksCount")
    echo $count
    
    # If the count <= 1 then it is instance without website 
    if [ "$count" -le "1" ]; then
        # Start the vault task on the correct instance 
        aws ecs start-task --cluster $CLUSTERNAME --task-definition  $TASK  --container-instances "$arn"
        echo "Starting vault container on empty instance $arn"
        exit;
    fi
done

echo "Failed to deploy Vault container. Could not find empty instance."