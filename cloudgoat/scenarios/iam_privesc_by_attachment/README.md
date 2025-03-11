# Scenario: iam_privesc_by_attachment

**Size:** Medium

**Difficulty:** Moderate

**Command:** `$ ./cloudgoat.py create iam_privesc_by_attachment`

## Scenario Resources

* 1 VPC with:
  * EC2 x 1
* 1 IAM User

## Scenario Start(s)

1. IAM User "Kerrigan"

## Scenario Goal(s)

Delete the EC2 instance "cg-super-critical-security-server."

## Summary

Starting with a very limited set of permissions, the attacker is able to leverage the instance-profile-attachment permissions to create a new EC2 instance with significantly greater privileges than their own. With access to this new EC2 instance, the attacker gains full administrative powers within the target account and is able to accomplish the scenario's goal - deleting the cg-super-critical-security-server and paving the way for further nefarious actions.

Note: This scenario may require you to create some AWS resources, and because CloudGoat can only manage resources it creates, you should remove them manually before running `./cloudgoat destroy`.

## Exploitation Route(s)

![Scenario Route(s)](https://www.lucidchart.com/publicSegments/view/17beef30-c547-4d58-912c-9b9250ea6c82/image.png)

## Walkthrough - IAM User "Kerrigan"

1. Starting as the IAM user "Kerrigan," the attacker uses their limited privileges to explore the environment.
2. The attacker first lists EC2 instances, identifying their target - the "cg-super-critical-security-server" - but being unable to directly affect the target, the attacker looks for another way...
3. The attacker decides to enumerate existing instance profiles and roles within the account, identifying an instance profile they can use and a promising-looking role.
4. With a plan in mind, the attacker prepares for their exploit. First, they swap the full-admin role onto the instance profile.
5. Next, the attacker creates a new EC2 key pair.
6. Then, the attacker creates a new EC2 instance with that keypair, meaning they now have shell access to it.
7. As the final step in the exploit, the attacker then attaches the full-admin-empowered instance profile to the EC2 instance.
8. By accessing and using the new EC2 instance as a staging platform, the attacker is able to execute AWS CLI commands with full admin privileges granted by the attached profile's role.
9. The attacker is finally able to terminate the "cg-super-critical-security-server" EC2 instance, completing the scenario.

A cheat sheet for this route is available [here](./cheat_sheet_kerrigan.md).