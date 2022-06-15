# Testing

## IMPORTANT

Tests load the default profile, *not* the profile specified by the cloudgoat config file.

Ensure the standard AWS environment variables are set correctly before running the tests here.

## Running tests

``
cd scenarios/cicd/terraform/test
ssh-keyscan git-codecommit.eu-west-1.amazonaws.com | tee -a ~/.ssh/known_hosts
go test .
``

