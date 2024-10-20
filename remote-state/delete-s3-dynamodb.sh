#!/bin/bash

# Variables
BUCKET_NAME="nicc-s3bucket"
DYNAMODB_TABLE_NAME="nicc-dynamoDB"
REGION="eu-west-1"
PROFILE="team2"

# Delete all objects in the S3 bucket
echo "Deleting all objects in S3 bucket: $BUCKET_NAME"
aws s3 rm s3://$BUCKET_NAME --recursive --profile $PROFILE

# Delete the S3 bucket
echo "Deleting S3 bucket: $BUCKET_NAME"
aws s3api delete-bucket --bucket $BUCKET_NAME --region $REGION --profile $PROFILE

# Delete the DynamoDB table
echo "Deleting DynamoDB table: $DYNAMODB_TABLE_NAME"
aws dynamodb delete-table --table-name $DYNAMODB_TABLE_NAME --region $REGION --profile $PROFILE

# Wait for the DynamoDB table to be deleted
echo "Waiting for DynamoDB table to be deleted"
echo "S3 bucket and DynamoDB table deleted successfully."
