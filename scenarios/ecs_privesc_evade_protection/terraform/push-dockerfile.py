# How to run:
# python3 push-dockerfile.py
import boto3
import subprocess
import base64
import argparse


def create_ecr_repository(client, repository_name):
    try:
        response = client.describe_repositories(repositoryNames=[repository_name])
        print(f"Repository {repository_name} already exists.")
        return response["repositories"][0]["repositoryUri"]
    except client.exceptions.RepositoryNotFoundException:
        print(f"Creating repository {repository_name}.")
        response = client.create_repository(repositoryName=repository_name)
        return response["repository"]["repositoryUri"]


def get_docker_login_cmd(client, region):
    token = client.get_authorization_token()["authorizationData"][0]
    username, password = (
        base64.b64decode(token["authorizationToken"]).decode().split(":")
    )
    registry = token["proxyEndpoint"]
    return f"docker login --username {username} --password {password} {registry}"


def docker_build_and_push(repository_uri, image_tag, path):
    # Build the Docker image
    subprocess.run(f"docker build -t {repository_uri}:{image_tag} {path}", shell=True, check=True)

    # Push the Docker image
    subprocess.run(f"docker push {repository_uri}:{image_tag}", shell=True, check=True)


def main():
    parser = argparse.ArgumentParser(description='Push Docker image to AWS ECR.')
    parser.add_argument('--repository', help='ECR repository name', required=True)
    parser.add_argument('--region', help='AWS region', default='us-east-1')
    parser.add_argument('--profile', help='AWS profile', default='default')
    parser.add_argument('--image_tag', help='Docker image tag', default='latest')
    parser.add_argument('--dockerfile_path', help='Path of Dockerfile', default='.')
    args = parser.parse_args()

    boto3.setup_default_session(profile_name=args.profile)

    client = boto3.client("ecr", region_name=args.region)

    # Step 1: Create ECR Repository
    repository_uri = create_ecr_repository(client, args.repository)
    print(f"Repository URI: {repository_uri}")

    # Step 2: Authenticate Docker with ECR
    docker_login_cmd = get_docker_login_cmd(client, args.region)
    subprocess.run(docker_login_cmd, shell=True, check=True)

    # Step 3: Build and Push Docker Image
    docker_build_and_push(repository_uri, args.image_tag, args.dockerfile_path)


if __name__ == "__main__":
    main()
