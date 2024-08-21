FROM amazonlinux:2

# Install dependencies
RUN yum install -y     python3     python3-pip     zip     && pip3 install --upgrade awscli

# Copy AWS credentials
COPY ~/.aws /root/.aws

# Copy the Lambda function script
COPY lambda_function.py /root/lambda_function.py

# Default command to run the Lambda function updater
CMD ["python3", "/root/lambda_function.py"]
