## Output Configuration for vpc_peering_overexposed scenario

# Initial access credentials
output "initial_access_key" {
  description = "The AWS access key for the initial user"
  value       = aws_iam_access_key.initial_user_key.id
}

output "initial_secret_key" {
  description = "The AWS secret key for the initial user"
  value       = aws_iam_access_key.initial_user_key.secret
  sensitive   = true
}

# Dev EC2 information
output "dev_ec2_public_ip" {
  description = "Public IP address of the Dev EC2 instance"
  value       = aws_instance.dev_ec2.public_ip
  sensitive   = true
}

output "dev_ec2_instance_id" {
  description = "Instance ID of the Dev EC2 instance"
  value       = aws_instance.dev_ec2.id
}

output "dev_ec2_ssh_key" {
  description = "Path to the SSH private key for the Dev EC2 instance"
  value       = "The SSH key is saved as cloudgoat.pem in the scenario directory"
}

# VPC information
output "dev_vpc_id" {
  description = "ID of the Dev VPC"
  value       = aws_vpc.dev_vpc.id
}

# Scenario instructions
output "scenario_instructions" {
  description = "Instructions to start the scenario"
  value       = <<-EOT
    ========================[ vpc_peering_overexposed ]========================
    
    You have successfully deployed the vpc_peering_overexposed scenario!
    
    Initial Access:
    - AWS Access Key: ${aws_iam_access_key.initial_user_key.id}
    - AWS Secret Key: ${aws_iam_access_key.initial_user_key.secret}
    
    SSH Access:
    - SSH Key: cloudgoat.pem (in the scenario directory)
    
    Your goal is to:
    1. Enumerate the AWS environment
    2. Exploit EC2 metadata service to gain higher privileges
    3. Identify and exploit VPC peering misconfigurations
    4. Move laterally to production environment 
    5. Access sensitive customer data

    Start by configuring the AWS CLI with the provided credentials:
    
        
    Good luck!
    ========================================================================
  EOT
  sensitive   = true
} 