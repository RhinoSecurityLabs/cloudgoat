This terraform code will deploy an EC2 instance in a VPC, with the VPC endpoints that are necessary to complete this scenario. Only a few AWS services are needed to be used at this stage in the scenario, so only the associated endpoints (and those required for SSM to function) are deployed.

In order to use this terraform code to finish the scenario you need to:
- Identify the IP of the ec2 instance you want to spoof (CloudTrails does not distinguish between public and private IPs in the "sourceIPAddress" field).
- In the variables.tf file, modify the "target_IP" variable to be the the IP from the first step.
- In the variables.tf file, modify the "target_CIDR_block" variable to be a CIDR block which contains your target IP. This is necessary for setting up a VPC. 
- run 'terraform apply'
- log into the consol and get a shell on the instance with ssm.

    ```bash
    # The following command will return a shell from the target instance. If you getting a (TargetNotConnected) error and you just deployed the resources, wait 10 min and try again. There can be a lag time before SSM works properly.
    aws --profile cg4 --region us-east-1 ssm start-session --target [INSTANCE_ID]
    ```
