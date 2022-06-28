# Testing

## Profile

Tests will run with the profile defined in config.yml in the root of this repo. This config
file is set up when running `./cloudgoat.py config profile`.

## Running tests

``
cd scenarios/cicd/terraform/test
ssh-keyscan git-codecommit.eu-west-1.amazonaws.com | tee -a ~/.ssh/known_hosts
go test .
``

