# Scenario: detection_evasion
**Size:**  Medium
**Difficulty:** Difficult

**Command:** $ ./cloudgoat.py create detection_evasion

## Scenario Resources
TBD

## Scenario Start(s)
4 IAM Users
## Scenario Goal(s)
Find the scenario's secret. (cg-secret-XXXXXX-XXXXXX)

## Summary (TLDR setup at the end)
This scenario is significantly different from all of the CloudGoat scenarios that have come before in how it plays. In detection_evasion, your goals will be outlined for you more clearly, and the challenge is to complete them without triggering alarms. There is more setup involved in this scenario, and it will take longer to play (you might want/need to play it multiple times). 

For starters, you will need to provide an email address to which cloudgoat can send email alerts. When you are detected by the automated mechanisms, an alert will be sent to this email address (and in some cases your access may be cut off). 

After deployment is complete, wait 15 minutes before playing the scenario (This is necessary for the cloudwatch alerts to fully integrate with cloudtrails logs). During this time, check your email address and confirm your subscription to the sns topic for alerts. It should also be kept in mind that there can be a significant delay in alerts for actions that you take (10-15 minutes is not uncommon). So check your email periodically to see if you have triggered an alert. 

After deploying the scenario and waiting for 15 minutes, you can begin playing. 

## Exploitation Route
Insert Lucidchart Diagram

## Walkthrough - IAM User "bilbo"
1. discover that some of the credentials initially given to you are honeytokens.
2. move onto the ec2 instance, and grab the credentials from IMDS



## TLDR Setup
1. update cloudgoat config file
2. deploy scenario
3. confirm email subscription
4. wait X minutes (or until email comes in telling you to start)
5. begin pentesting