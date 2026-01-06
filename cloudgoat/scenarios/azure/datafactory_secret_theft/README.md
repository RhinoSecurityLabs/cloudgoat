# Scenario: datafactory_secret_theft
**Size:** Small  
**Dificulty:** Easy  
**Command:** `cloudgoat create datafactory_secret_theft`  

## Scenario Resources
- 1 Data Factory (ADF)
- 1 Key Vault

## Scenario Start(s)
1. Azure user: `cloudgoat-user[ID]@rhinosecuritylabs.onmicrosoft.com`
2. Data Factory URL

## Scenario Goal(s)
Obtain the flag from Key Vault.

## Summary
Starting as the CloudGoat created user, access the Data Factory and figure out how to exfiltrate secrets from the linked service Key Vault.

## Route Walkthrough
1. Using the provided credentials and Data Factory URL, log into Data Factory.
2. Identify the linked service Key Vault and its name.
3. Use a Data Factory Pipeline web request to exfiltrate the secret name and secret value.

A cheat sheet for this route is available [here](./cheat_sheet.md).