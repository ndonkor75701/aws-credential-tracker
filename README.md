# aws-credential-tracker

## Description
Leverages the AWS credentials report to run schedule bulk checks against an account so that IAM credentials, access keys and certificates are controlled.

## Architecture
![alt text][arch-image]

## Component Breakdown

### Identity and Access Management (IAM)
AWS IAM is used to securely control individual and group access to your AWS resources. You can create and manage user identities ("IAM users") and grant permissions for those IAM users to access your resources. You can also grant permissions for users outside of AWS.

The credential tracker is executed under the credentials tracker execution role.  An IAM role is an IAM entity that defines a set of permissions for making AWS service requests. IAM roles are not associated with a specific user or group. Instead, trusted entities assume roles, such as IAM users, applications, or AWS services such as EC2.

#### Permissions
The credentials tracker role has both an [execution permissions policy] and an [assume role policy].

#### Credential Report
The IAM credential reports can be used to assist in your auditing and compliance efforts. You can use the report to audit the effects of credential lifecycle requirements, such as password and access key rotation. You can provide the report to an external auditor, or grant permissions to an auditor so that he or she can download the report directly.

You can generate a credential report as often as once every four hours. When you request a report, IAM first checks whether a report for the AWS account has been generated within the past four hours. If so, the most recent report is downloaded. If the most recent report for the account is older than four hours, or if there are no previous reports for the account, IAM generates and downloads a new report.

### Cloudwatch
Cloudwatch is used to trigger the Step Functions state machine.  The tirgger is time based and when first deployed is set to run every day at 00:15.  The trigger time is configurable in the [variables.tf] file.

### Step Functions
Step Functions provides a reliable way to coordinate components and step through the functions of your application.  For the credentials tracker the state machine moves through 5 specific states.

**1. Generate Report**

⋅⋅⋅During this step Step Functions calls the generate-report Lambda function which requests a new report be generated ⋅⋅⋅by the IAM service.

**2. Download Report**

⋅⋅⋅During this step Step Functions calls the download-report Lambda function which downloads the latest generated report and places it into S3.  

**3. Initialise Table**

⋅⋅⋅During this step Step Functions calls the initialise-report Lambda function which creates a table in Athena and loads the data partitions to make the data queryable in the Generate Findings step.

**4. Generate Findings**

⋅⋅⋅During this step Step Functions calls the generate-findings Lambda function followed by the retrieve-users-to-remediate function.  The generate findings lambda function is parameterised so when it is deployed through Terraform it creates a function per finding.  A parameter is used to define which named Athena query needs to be executed to retrieve the correct users from the query result in the retrieve-users-to-remediate lambda.

⋅⋅⋅[generate-findings]

**5. Remediate Findings**

⋅⋅⋅During this step Step Functions calls the remediate-findings Lambda function releated to the specific finding it needs to remediate.

⋅⋅⋅[remediate-findings_ak-rotation]

⋅⋅⋅[remediate-findings_ak-usage]

⋅⋅⋅[remediate-findings_cert-rotation]

⋅⋅⋅[remediate-findings_cred-usage]

### Athena

### Lambda

### Simple Storage Service (S3)

## How to deploy

## How to run
### Time based execution
### Manual Execution
**Note:** If running manually you will notice that a new Credential Report is not created for every request.  If a new credential report is not created the step functions state object will inform you of this and provide the time of the report that will be referenced for the manaual run.

[execution permissions policy]: /policies/lambda-execution.json.tpl
[assume role policy]: aws-credential-tracker/policies/lambda-trust.json
[arch-image]: /images/credential-tracker.png
[variables.tf]: /variables.tf
[generate-report]: /lambdas/generate-report/generate-report.py
[generate-findings]: /lambdas/generate-findings/generate-findings.py
[remediate-findings_ak-rotation]: /lambdas/remediate-findings_ak-rotation/remediate-findings_ak-rotation.py
[remediate-findings_ak-usage]: /lambdas/remediate-findings_ak-usage/remediate-findings_ak-usage.py
[remediate-findings_cert-rotation]: /lambdas/remediate-findings_cert-rotation/remediate-findings_cert-rotation.py
[remediate-findings_cred-usage]: /lambdas/remediate-findings_cred-usage/remediate-findings_cred-usage.py
