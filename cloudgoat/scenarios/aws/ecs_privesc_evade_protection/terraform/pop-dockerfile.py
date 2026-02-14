import boto3
import argparse


def delete_all_images(client, repository_name):
    try:
        response = client.list_images(repositoryName=repository_name)
        image_ids = response['imageIds']

        if not image_ids:
            print("No images to delete.")
            return

        delete_response = client.batch_delete_image(
            repositoryName=repository_name,
            imageIds=image_ids
        )

        if delete_response['failures']:
            print("Failed to delete some images:", delete_response['failures'])
        else:
            print(f"All images in '{repository_name}' deleted successfully.")
    except Exception as e:
        print("Error deleting images:", e)


def delete_ecr_image(client, repository_name, image_tag):
    try:
        response = client.batch_delete_image(
            repositoryName=repository_name,
            imageIds=[{'imageTag': image_tag}]
        )
        if response['failures']:
            print("Failed to delete the image:", response['failures'])
        else:
            print(f"Image with tag '{image_tag}' deleted successfully.")
    except Exception as e:
        print("Error deleting image:", e)


def main():
    parser = argparse.ArgumentParser(description='Delete Docker image from AWS ECR.')
    parser.add_argument('--repository', help='ECR repository name', required=True)
    parser.add_argument('--region', help='AWS region', default='us-east-1')
    parser.add_argument('--profile', help='AWS profile', default='default')
    parser.add_argument('--image_tag', help='Docker image tag', required=True)
    args = parser.parse_args()

    boto3.setup_default_session(profile_name=args.profile)
    client = boto3.client("ecr", region_name=args.region)

    # Remove Docker image on ECR.
    delete_all_images(client, args.repository) if args.image_tag == 'all' else delete_ecr_image(client, args.repository, args.image_tag)


if __name__ == "__main__":
    main()
