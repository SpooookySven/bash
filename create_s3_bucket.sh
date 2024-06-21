#!/usr/bin/env bash
# $1 = bucket-/tablename , e.g. tf-state-19920811 

NAME=$1

aws dynamodb create-table \
    --table-name $NAME \
    --attribute-definitions \
        AttributeName=TFLock,AttributeType=S \
    --key-schema \
        AttributeName=TFLock,KeyType=HASH \
    --provisioned-throughput \
        ReadCapacityUnits=5,WriteCapacityUnits=5

TEMPLATE_FILE=$(mktemp)

cat <<EOF > $TEMPLATE_FILE
AWSTemplateFormatVersion: "2010-09-09"
Description: Terraform state bucket s3
# S3 bucket for terraform state files
Parameters:
  MyBucketName:
    Type: String
Resources:
  TerraformStateBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Ref MyBucketName
      VersioningConfiguration:
        Status: Enabled
      AccessControl: BucketOwnerFullControl
# KMS key for state file encryption
  KMSKeyAlias:
    Type: AWS::KMS::Alias
    Properties:
      AliasName: !Sub alias/\${MyBucketName}-key
      TargetKeyId:
        Ref: KMSKey
  KMSKey:
    Type: AWS::KMS::Key
    Properties:
        KeyPolicy:
          Version: "2012-10-17"
          Id: !Sub \${MyBucketName}-key-policy
          Statement:
            - Sid: Allow access for Key Administrators
              Effect: Allow
              Principal:
                AWS: [!Sub "arn:aws:iam::\${AWS::AccountId}:root"]
              Action:
                - kms:Create*
                - kms:Describe*
                - kms:Enable*
                - kms:List*
                - kms:Put*
                - kms:Update*
                - kms:Revoke*
                - kms:Disable*
                - kms:Get*
                - kms:Delete*
                - kms:TagResource
                - kms:UntagResource
                - kms:ScheduleKeyDeletion
              Resource: "*"
            - Sid: Allow use of the key
              Effect: Allow
              Principal:
                AWS: [!Sub "arn:aws:iam::\${AWS::AccountId}:root"]
              Action:
                - kms:Encrypt
                - kms:Decrypt
                - kms:ReEncrypt*
                - kms:GenerateDataKey*
                - kms:DescribeKey
              Resource: "*"
EOF

aws cloudformation deploy \
    --stack-name $NAME \
    --template-file $TEMPLATE_FILE \
    --capabilities CAPABILITY_IAM \
    --parameter-overrides "MyBucketName=$NAME"

rm $TEMPLATE_FILE
