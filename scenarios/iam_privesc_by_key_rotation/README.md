
# Scenario: iam_privesc_by_key_rotation

**Size:** Small  
**Difficulty:** Easy

**Command:** `$ ./cloudgoat.py create iam_privesc_by_key_rotation`

## Scenario Resources

- 3 IAM User
- 1 IAM Role
- 1 Secret

## Scenario Start(s)

1. IAM User "devops"

## Scenario Goal(s)

Retrieve AWS secret

## Summary

<details>
  <summary>Spoiler warning</summary>
  
  1. Starting with the devops user add a tag to the admin iam user
  2. Delete and add a new access key to the admin user
  3. Create and attach a MFA device to the admin user
  4. Switch to the admin user
  5. Assume the secretsmanager role with MFA
  6. Retrieve the secret

  A full cheat_sheet can be found [here](./cheat_sheet.md)

  ![Scenario Route(s)](image.jpeg)  
</details>
