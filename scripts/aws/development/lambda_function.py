import boto3
import os

def update_github_pages():
    # Initialize the Lambda client
    lambda_client = boto3.client('lambda', region_name='your-region')

    # Invoke the Lambda function
    response = lambda_client.invoke(
        FunctionName='update-github-pages',
        InvocationType='RequestResponse',
        LogType='Tail'
    )

    print("Lambda function invoked, status code:", response['StatusCode'])

if __name__ == "__main__":
    update_github_pages()
