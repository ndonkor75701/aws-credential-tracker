# aws-credential-tracker

## Description
Leverages the AWS credentials report to run schedule bulk checks against an account so that IAM credentials, access keys and certificates are controlled.

## Architecture
![alt text][arch-image]

[arch-image]: /images/credential-tracker.png

## Component Breakdown

### IAM

#### Permissions

#### Credential Report

### Cloudwatch

### Step Functions

### Athena

### Lambda

### Simple Storage Service (S3)

## How to deploy

## How to run
### Time based execution
### Manual Execution
**Note:** If running manually you will notice that a new Credential Report is not created for every request.  If a new credential report is not created the step functions state object will inform you of this and provide the time of the report that will be referenced for the manaual run.
