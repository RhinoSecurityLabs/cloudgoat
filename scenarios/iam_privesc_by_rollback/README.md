# Scenario: iam_privesc_by_rollback

**Size:** Small

**Difficulty:** Easy

**Command:** `$ ./cloudgoat.py create iam_privesc_by_rollback`

## Scenario Resources

* 1 IAM User
  * 5 policy versions

## Scenario Start(s)

1. IAM User "Raynor"

## Scenario Goal(s)

Acquire full admin privileges.

## Summary

Starting with a highly-limited IAM user, the attacker is able to review previous IAM policy versions and restore one which allows full admin privileges, resulting in a privilege escalation exploit.

## Exploitation Route(s)

![Scenario Route(s)](https://www.lucidchart.com/publicSegments/view/acef779c-51ce-4582-b4d2-19ae92b7f170/image.png)

## Route Walkthrough - IAM User "Raynor"

1. Starting as the IAM user "Raynor," the attacker has only a few limited - seemingly harmless - privileges available to them.
2. The attacker analyzes Raynor's privileges and notices the SetDefaultPolicyVersion permission - allowing access to 4 other versions of the policy via setting an old version as the default.
3. After reviewing the old policy versions, the attacker finds that one version in particular offers a full set of admin rights.
4. Attacker restores the full-admin policy version, gaining full admin privileges and the ability to carry out any malicious actions they wish.
5. As a final step, the attacker may choose to revert Raynor's policy version back to the original one, thereby concealing their actions and the true capabilities of the IAM user.

A cheat sheet for this route is available [here](./cheat_sheet_raynor.md).