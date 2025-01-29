#!/bin/bash

# # # Destroy Jenkins server
# cd ./jenkins
# terraform destroy -auto-approve

# Variables
BUCKET_NAME="nicc-s3bucket"
TABLE_NAME="nicc-dynamoDB"
REGION="eu-west-1"
PROFILE="personal"

# Function to delete all objects in the S3 bucket and then the bucket itself
delete_s3_bucket() {
  echo "Deleting all objects from S3 bucket: $BUCKET_NAME"
  
  # Remove all objects and versions (if versioning is enabled) from the bucket
  aws s3 rm s3://$BUCKET_NAME --recursive --profile $PROFILE
  
  if [ $? -eq 0 ]; then
    echo "All objects deleted from bucket $BUCKET_NAME."
    
    echo "Deleting S3 bucket: $BUCKET_NAME"
    # Now delete the empty bucket
    aws s3api delete-bucket \
      --bucket $BUCKET_NAME \
      --region $REGION \
      --profile $PROFILE \

    if [ $? -eq 0 ]; then
      echo "S3 bucket $BUCKET_NAME deleted successfully."
    else
      echo "Failed to delete S3 bucket."
    fi
  else
    echo "Failed to delete objects from bucket."
  fi
}

# Function to delete the DynamoDB table
delete_dynamodb_table() {
  echo "Deleting DynamoDB table: $TABLE_NAME"
  
  aws dynamodb delete-table \
    --table-name $TABLE_NAME \
    --region $REGION \
    --profile $PROFILE

  if [ $? -eq 0 ]; then
    echo "DynamoDB table $TABLE_NAME deleted successfully."
  else
    echo "Failed to delete DynamoDB table."
  fi
}

# Delete S3 bucket and DynamoDB table
delete_s3_bucket
delete_dynamodb_table
