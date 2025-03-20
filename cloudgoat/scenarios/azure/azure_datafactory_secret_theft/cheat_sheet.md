
---

### **8. cheat_sheet.md**
Hints for attackers.

```markdown
# Hints for Azure Data Factory Secret Theft

### Enumerate Linke Services
1. Open the Data Factory URL and log in as the starting CloudGoat user.
2. Click "Manage" > "Linked services".
3. Note the linked Key Vault and it's name.

### Exfiltrate the secret using Pipeline's "Web" feature
1. Click "Author" > "Pipelines" > "New Pipeline".
2. Drop down "General".
3. Drag "Web" to the Pipeline designer.
4. Click "Settings".
5. Set the URL to https://{vault-name}.vault.azure.net/secrets?api-version=7.3
6. Set Method to "GET".
7. Set "Authentication" to "system-assigned managed identity". (This will use the privileges assigned to the Data Factory).
8. Set the "Resource" to https://vault.azure.net/.
9. Click "Debug".
10. Wait for the requst to complete and click output to view the response of the request containing the secret name.
11. Repeat this but use the URL:  https://{vault-name}.vault.azure.net/{secret_name_from_step_10}?api-version=7.3
12. This response will give you the flag contained in Key Vault.