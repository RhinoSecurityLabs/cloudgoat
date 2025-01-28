This terraform code will deploy an EC2 instance in a VPC, with the VPC endpoints that are necessary to complete this scenario. Only a few AWS services are needed to be used at this stage in the scenario, so only the associated endpoints (and those required for SSM to function) are deployed.

In order to use this terraform code to finish the scenario you need to:
* Identify the IP of the ec2 instance you want to spoof (CloudTrails does not distinguish between public and private IPs in the "sourceIPAddress" field).
* run `terraform init`
* run `terraform apply -var profile="__aws_profile_name__" -var target_ip="__ec2.instance.ip.addr__"`
  * This assumes the instance IP is in the `3.84.104.*` range. If it's not, you'll need to set `-var target_cidr_block="__cidr.ip.block__/24"
* Ensure the SSM awscli plugin is installed ([SSM plugin install docs](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)).
* log into the console and get a shell on the instance with ssm.

    ```bash
    # The following command will return a shell from the target instance. If you getting a (TargetNotConnected) error and you just deployed the resources, wait 10 min and try again. There can be a lag time before SSM works properly.
    aws --profile cg4 --region us-east-1 ssm start-session --target [INSTANCE_ID]
    ```
