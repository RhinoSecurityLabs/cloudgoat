# Azure Databricks Privilege Escalation Scenario

## Scenario Overview
This scenario deploys:
- An Azure Databricks workspace
- A Databricks cluster VM
- Grants the cluster Owner rights at the subscription level
- Exposes the Databricks API Key via a deployment template

## Attack Path
1. Attacker gains access to the Databricks cluster.
2. They discover the API key stored in the deployment template.
3. Using the key, they escalate privileges to perform administrative actions.
4. Since the cluster has Owner permissions, they gain control over the entire Azure subscription.

## Deployment
```sh
cloudgoat.py create azure_databricks_privilege_escalation
