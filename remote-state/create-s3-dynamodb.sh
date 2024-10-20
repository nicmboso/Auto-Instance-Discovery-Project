#!/bin/bash

# Variables names
BUCKET_NAME="nicc-s3bucket"
DYNAMODB_TABLE_NAME="nicc-dynamoDB"
REGION="eu-west-1"
PROFILE="team2"

# Create S3 Bucket
echo "Creating S3 bucket: $BUCKET_NAME"
aws s3api create-bucket --bucket $BUCKET_NAME --region $REGION --profile $PROFILE --create-bucket-configuration LocationConstraint=$REGION

# Tagging the S3 bucket
aws s3api put-bucket-tagging --bucket $BUCKET_NAME --tagging 'TagSet=[{Key=Name,Value=team2-remote-tf}]' --profile $PROFILE

# Create DynamoDB Table
echo "Creating DynamoDB table: $DYNAMODB_TABLE_NAME"
aws dynamodb create-table \
    --table-name $DYNAMODB_TABLE_NAME \
    --attribute-definitions \
        AttributeName=LockID,AttributeType=S \
    --key-schema \
        AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput \
        ReadCapacityUnits=10,WriteCapacityUnits=10 \
    --region $REGION \
    --profile $PROFILE

# Wait for the DynamoDB table to become ACTIVE
echo "Waiting for DynamoDB table to become ACTIVE"
echo "S3 bucket and DynamoDB table created successfully."
