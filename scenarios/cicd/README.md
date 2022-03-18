# Scenario: cicd

**Size:** Medium

**Difficulty:** Moderate

**Command:** `$ ./cloudgoat.py create cicd`

## Scenario Resources

* 3 IAM users
* 1 VPC with 1 EC2 instance
* 1 API Gateway
* 1 Lambda function
* 1 ECR image
* 2 CodeBuild project (and an additional out of scope)

## Scenario Start

You are provided with the access key ID and secret access key of an initial IAM user.

## Scenario Story

FooCorp is a company exposing a public-facing API. Customers of FooCorp submit sensitive data to the API every minute to the following API endpoint:

```
POST {apiUrl}/prod/hello
Host: {apiHost}
Content-Type: text/html

superSecretData=...
```

The API is implemented as a Lambda function, exposed through an API Gateway. 

Because FooCorp implements DevOps, it has a continuous deployment pipeline automatically deploying new versions of their Lambda function from source code to production in under a few minutes.

## Scenario Goal

Retrieve the sensitive data submitted by customers.

Note that simulated user activity is taking place in the account. This is implemented through a CodeBuild project running every minute and simulating customers requests to the API. This CodeBuild project is out of scope.

## Summary

<details>
  <summary>Spoiler warning</summary>
  
  You get access to an initial AWS access key. Escalate your privileges by overwriting the tag of an EC2 instance used for attribute-based access control. Steal the SSH key on the instance, and use it to clone a CodeCommit repository. Go through the commit history, and find a new set of AWS credentials. Use them to backdoor the application and steal the sensitive data.
  
</details>

## Route Walkthrough 

A cheat sheet for this route is available [here](./cheat_sheet.md).

## End-to-end tests

This scenario has end-to-end testing using [Terratest](https://terratest.gruntwork.io/). The tests will:

1. Spin up the environment through Terraform instrumentation
2. Unroll the compromission scenario to ensure it is working
3. Tear down the environment

To run, you'll need to have [Golang installed](https://go.dev/doc/install). use:

```
cd terraform/test
go get .
go test -v
```