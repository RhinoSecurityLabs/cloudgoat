
---

### **8. cheat_sheet.md**
Hints for attackers.

```markdown
# Hints for Azure Data Factory Secret Theft

1. Identify the Datafactory has a connection to **keyvault**.
2. Look for **Storage Account keys**.
3. Use the exposed **keys** to interact with Storage data.
4. Check the Data Factory **Linked Services** for additional secrets.
