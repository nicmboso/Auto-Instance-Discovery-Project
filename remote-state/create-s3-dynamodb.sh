#!/bin/bash
# set -x
# Variables names
BUCKET_NAME="nicc-s3bucket"
DYNAMODB_TABLE_NAME="nicc-dynamoDB"
REGION="eu-west-1"
PROFILE="team-20"

# Function to create an S3 bucket
create_s3_bucket() {
  echo "Creating S3 bucket: $BUCKET_NAME"
  
  aws s3api create-bucket \
    --bucket $BUCKET_NAME \
    --region $REGION \
    --profile $PROFILE \
    --create-bucket-configuration LocationConstraint=$REGION

  if [ $? -eq 0 ]; then
    echo "S3 bucket $BUCKET_NAME created successfully."
  else
    echo "Failed to create S3 bucket."
  fi
}

# Function to create a DynamoDB table
create_dynamodb_table() {
  echo "Creating DynamoDB table: $DYNAMODB_TABLE_NAME"
  
  aws dynamodb create-table \
    --table-name $DYNAMODB_TABLE_NAME \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region $REGION \
    --profile $PROFILE 

  if [ $? -eq 0 ]; then
    echo "DynamoDB table $DYNAMODB_TABLE_NAME created successfully."
  else
    echo "Failed to create DynamoDB table."
  fi
}

# Create S3 bucket and DynamoDB table
create_s3_bucket
create_dynamodb_table

# # # Create a Jenkins server
cd ../Jenkins
terraform init
terraform fmt --recursive
terraform validate
terraform apply -auto-approve
