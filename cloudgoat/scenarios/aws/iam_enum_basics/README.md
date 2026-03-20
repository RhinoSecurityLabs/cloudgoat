Scenario: iam_enum_basics
=========================

**Size:** Small

**Difficulty:** Easy

**Command:** `./cloudgoat.py create iam_enum_basics`

Scenario Resources
------------------

-   1 IAM User

-   1 IAM Group

-   1 IAM Role

-   1 IAM Managed Policy

-   1 IAM Inline Policy

Scenario Start(s)
-----------------

1.  AWS Access Key and Secret Key

Scenario Goal(s)
----------------

Find the 5 hidden flags (formatted as `HSM{text}` or similar) by manually enumerating IAM resources and metadata using the AWS CLI.

Summary
-------

In this scenario, you start with the access keys for a low-level IAM user named Bob. Your task is to perform thorough IAM enumeration using the AWS CLI. By investigating managed policies, inline policies, group memberships, and assumable roles, you will uncover five distinct flags hidden deep within the AWS resource metadata (such as descriptions, Statement IDs, hierarchical paths, tags, and JSON target resources).

Exploitation Route
------------------

Walkthrough - IAM Enumeration Basics
------------------------------------

1.  Start by configuring your AWS CLI with the provided starting credentials.

2.  Enumerate the attached managed policies and read their metadata to find Flag 1 in the policy's Description.

3.  Enumerate inline user policies and parse the JSON document to find Flag 2 hidden in the Statement ID (`Sid`).

4.  List the user's group memberships to find Flag 3 hidden within the group's organizational Path.

5.  Enumerate the IAM roles in the account and inspect the target role's metadata to find Flag 4 stored in the AWS Tags.

6.  Retrieve the default version of the managed policy document to find Flag 5 hidden as the target Resource ARN.

A detailed cheat sheet & walkthrough for this route is available [here](cheatsheet.md).