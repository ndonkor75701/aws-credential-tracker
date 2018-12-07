##<-- S3
locals {
  environment-bucket-name = "${var.environment-name}-${var.aws-account-number}"
}

resource "aws_s3_bucket" "secure-baseline-bucket" {
  bucket = "${local.environment-bucket-name}"
  acl    = "private"

  tags {
    Name        = "${local.environment-bucket-name}"
  }
  lifecycle {
    prevent_destroy = false
  }
}
##--> S3

##<-- IAM
# IAM Role for Lambda executions made by the Credentials Tracker
resource "aws_iam_role" "execution-role" {
  name = "credentialsTracker-execution-role"
  assume_role_policy = "${file("./policies/lambda-trust.json")}"
}

data "template_file" "lambda-execution-policy" {
  template = "${file("./policies/lambda-execution.json.tpl")}"

  vars {
    bucket-name = "${local.environment-bucket-name}"
    generate-report-lambda-arn = "${aws_lambda_function.generate-report.arn}"
    download-report-lambda-arn = "${aws_lambda_function.download-report.arn}"
    initialise-report-lambda-arn = "${aws_lambda_function.initialise-report.arn}"
    generate-findings_ak-usage-period-lambda-arn = "${aws_lambda_function.generate-findings_ak-usage-period.arn}"
    generate-findings_cred-usage-period-lambda-arn = "${aws_lambda_function.generate-findings_cred-usage-period.arn}"
    generate-findings_ak-rotation-period-lambda-arn = "${aws_lambda_function.generate-findings_ak-rotation-period.arn}"
    generate-findings_cert-rotation-period-lambda-arn = "${aws_lambda_function.generate-findings_cert-rotation-period.arn}"
    retrieve-users-to-remediate-lambda-arn = "${aws_lambda_function.retrieve-users-to-remediate.arn}"
    remediate-findings_ak-usage-period-lambda-arn = "${aws_lambda_function.remediate-findings_ak-usage-period.arn}"
    remediate-findings_cred-usage-period-lambda-arn = "${aws_lambda_function.remediate-findings_cred-usage-period.arn}"
    remediate-findings_ak-rotation-period-lambda-arn = "${aws_lambda_function.remediate-findings_ak-rotation-period.arn}"
    remediate-findings_cert-rotation-period-lambda-arn = "${aws_lambda_function.remediate-findings_cert-rotation-period.arn}"
  }
}

# Assume role trust policy for the Credentials Tracker execution role
resource "aws_iam_policy" "lambda-execution" {
  name        = "credentials-tracker-execution-policy"
  description = "Credentials Tracker execution policy"
  policy = "${data.template_file.lambda-execution-policy.rendered}"
}

# Attached execution policy for the Credentials Tracker execution role
resource "aws_iam_role_policy_attachment" "policy-attach" {
  role       = "${aws_iam_role.execution-role.name}"
  policy_arn = "${aws_iam_policy.lambda-execution.arn}"
}

# Attach AWS managed policy for the Credentials Tracker execution role to use Glue
resource "aws_iam_role_policy_attachment" "policy-attach-glue" {
  role       = "${aws_iam_role.execution-role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}
##--> IAM

##<-- Lambda functions
# Generate local maps of query ID's and output paths for use in Lambda functions
/*
Currently Step Functions cannot refer to the step being executed in the Lambda
context.  The Lambda function code has been written to support this
functionality, however it has currently been implemented with a duplicate of the
Lambda function for each named query with a hard coded value passed for the
 relevant named query to execute from the map.
*/
locals {
  namedQueryMap = {
    akRotationPeriod = "${aws_athena_named_query.ak-rotation-period.id}"
    akUsagePeriod = "${aws_athena_named_query.ak-usage-period.id}"
    certRotationPeriod = "${aws_athena_named_query.cert-rotation-period.id}"
    credUsagePeriod = "${aws_athena_named_query.cred-usage-period.id}"
  },
  outputPathMap = {
    akRotationPeriodOutputPath = "${var.ak-rotation-period-output-path}"
    akUsagePeriodOutputPath = "${var.ak-usage-period-output-path}"
    certRotationPeriodOutputPath = "${var.cred-usage-period-output-path}"
    credUsagePeriodOutputPath = "${var.cred-usage-period-output-path}"
  }
}

# Create Lambda function zip for generate-report
data "archive_file" "generate-report" {
  type        = "zip"
  source_file = "./lambdas/generate-report/generate-report.py"
  output_path = "./lambdas/zips/generate-report.zip"
}

# Create Lambda function zip for download-report
data "archive_file" "download-report" {
  type        = "zip"
  source_file = "./lambdas/download-report/download-report.py"
  output_path = "./lambdas/zips/download-report.zip"
}

# Create Lambda function zip for initialise-report in Athena
data "archive_file" "initialise-report" {
  type        = "zip"
  source_file = "./lambdas/initialise-report/initialise-report.py"
  output_path = "./lambdas/zips/initialise-report.zip"
}

# Create Lambda function zip for generating findings from the report
data "archive_file" "generate-findings" {
  type        = "zip"
  source_file = "./lambdas/generate-findings/generate-findings.py"
  output_path = "./lambdas/zips/generate-findings.zip"
}

# Create Lambda function zip for getting users to remediate
data "archive_file" "retrieve-users-to-remediate" {
  type        = "zip"
  source_file = "./lambdas/retrieve-users-to-remediate/retrieve-users-to-remediate.py"
  output_path = "./lambdas/zips/retrieve-users-to-remediate.zip"
}

# Create Lambda function zip for remediating ak-rotation findings from the report
data "archive_file" "remediate-findings_ak-rotation" {
  type        = "zip"
  source_file = "./lambdas/remediate-findings_ak-rotation/remediate-findings_ak-rotation.py"
  output_path = "./lambdas/zips/remediate-findings_ak-rotation.zip"
}

# Create Lambda function zip for remediating ak-usage findings from the report
data "archive_file" "remediate-findings_ak-usage" {
  type        = "zip"
  source_file = "./lambdas/remediate-findings_ak-usage/remediate-findings_ak-usage.py"
  output_path = "./lambdas/zips/remediate-findings_ak-usage.zip"
}

# Create Lambda function zip for remediating cert-rotation findings from the report
data "archive_file" "remediate-findings_cert-rotation" {
  type        = "zip"
  source_file = "./lambdas/remediate-findings_cert-rotation/remediate-findings_cert-rotation.py"
  output_path = "./lambdas/zips/remediate-findings_cert-rotation.zip"
}

# Create Lambda function zip for remediating cred-usage findings from the report
data "archive_file" "remediate-findings_cred-usage" {
  type        = "zip"
  source_file = "./lambdas/remediate-findings_cred-usage/remediate-findings_cred-usage.py"
  output_path = "./lambdas/zips/remediate-findings_cred-usage.zip"
}

# Lambda function that generates the credentials report
resource "aws_lambda_function" "generate-report" {
  filename         = "${data.archive_file.generate-report.output_path}"
  function_name    = "credentials-tracker-generate-report"
  role             = "${aws_iam_role.execution-role.arn}"
  handler          = "generate-report.lambda_handler"
  source_code_hash = "${base64sha256(file(data.archive_file.generate-report.output_path))}"
  runtime          = "python3.6"
  timeout          = 10
  environment{
    variables = {
      generateWaitTime = "${var.credential-report-generation-wait-time}"
    }
  }
}

# Lambda function that checks status and downloads the credentials report
resource "aws_lambda_function" "download-report" {
  filename         = "${data.archive_file.download-report.output_path}"
  function_name    = "credentials-tracker-download-report"
  role             = "${aws_iam_role.execution-role.arn}"
  handler          = "download-report.lambda_handler"
  source_code_hash = "${base64sha256(file(data.archive_file.download-report.output_path))}"
  runtime          = "python3.6"
  timeout          = 60
  environment{
    variables = {
      bucketName = "${local.environment-bucket-name}"
      prefix = "${var.credentials-tracker-prefix}"
      fileName = "report.csv"
    }
  }
}

# Lambda function that processes the credentials report and creates findings
resource "aws_lambda_function" "initialise-report" {
  filename         = "${data.archive_file.initialise-report.output_path}"
  function_name    = "credentials-tracker-initialise-report"
  role             = "${aws_iam_role.execution-role.arn}"
  handler          = "initialise-report.lambda_handler"
  source_code_hash = "${base64sha256(file(data.archive_file.initialise-report.output_path))}"
  runtime          = "python3.6"
  timeout          = 60
  environment{
    variables = {
      bucketName = "${local.environment-bucket-name}"
      credentialsReport = "${aws_athena_named_query.credentials-report.id}"
      repairCredentialReport = "${aws_athena_named_query.partition-update.id}"
      credentialsReportOutputPath = "${var.credentials-report-output-path}"
      encryptionOption = "${var.athena-output-encryption-option}"
      kmsKey = "${var.athena-output-encryption-kms-key}"
    }
  }
  depends_on = [
    "aws_athena_named_query.credentials-report",
    "aws_athena_named_query.partition-update"
  ]
}

# Lambda function that creates findings from the generated credentials report
resource "aws_lambda_function" "generate-findings_ak-rotation-period" {
  filename         = "${data.archive_file.generate-findings.output_path}"
  function_name    = "credentials-tracker-generate-findings_ak-rotation-period"
  role             = "${aws_iam_role.execution-role.arn}"
  handler          = "generate-findings.lambda_handler"
  source_code_hash = "${base64sha256(file(data.archive_file.generate-findings.output_path))}"
  runtime          = "python3.6"
  timeout          = 60
  environment{
    variables = "${merge(
      map(
        "namedQuery", "akRotationPeriod",
        "bucketName", "${local.environment-bucket-name}",
        "encryptionOption", "${var.athena-output-encryption-option}",
        "kmsKey", "${var.athena-output-encryption-kms-key}",
        "periodInDays", "${var.ak-rotation-period-in-days}"
      ),
      local.namedQueryMap,
      local.outputPathMap
      )}"
  }
  depends_on = [
    "aws_athena_named_query.ak-rotation-period",
    "aws_athena_named_query.ak-usage-period",
    "aws_athena_named_query.cert-rotation-period",
    "aws_athena_named_query.cred-usage-period"
  ]
}

# Lambda function that creates findings from the generated credentials report
resource "aws_lambda_function" "generate-findings_ak-usage-period" {
  filename         = "${data.archive_file.generate-findings.output_path}"
  function_name    = "credentials-tracker-generate-findings_ak-usage-period"
  role             = "${aws_iam_role.execution-role.arn}"
  handler          = "generate-findings.lambda_handler"
  source_code_hash = "${base64sha256(file(data.archive_file.generate-findings.output_path))}"
  runtime          = "python3.6"
  timeout          = 60
  environment{
    variables = "${merge(
      map(
        "namedQuery", "akUsagePeriod",
        "bucketName", "${local.environment-bucket-name}",
        "encryptionOption", "${var.athena-output-encryption-option}",
        "kmsKey", "${var.athena-output-encryption-kms-key}",
        "periodInDays", "${var.ak-usage-period-in-days}"
      ),
      local.namedQueryMap,
      local.outputPathMap
      )}"
  }
  depends_on = [
    "aws_athena_named_query.ak-rotation-period",
    "aws_athena_named_query.ak-usage-period",
    "aws_athena_named_query.cert-rotation-period",
    "aws_athena_named_query.cred-usage-period"
  ]
}

# Lambda function that creates findings from the generated credentials report
resource "aws_lambda_function" "generate-findings_cert-rotation-period" {
  filename         = "${data.archive_file.generate-findings.output_path}"
  function_name    = "credentials-tracker-generate-findingscert-rotation-period"
  role             = "${aws_iam_role.execution-role.arn}"
  handler          = "generate-findings.lambda_handler"
  source_code_hash = "${base64sha256(file(data.archive_file.generate-findings.output_path))}"
  runtime          = "python3.6"
  timeout          = 60
  environment{
    variables = "${merge(
      map(
        "namedQuery", "certRotationPeriod",
        "bucketName", "${local.environment-bucket-name}",
        "encryptionOption", "${var.athena-output-encryption-option}",
        "kmsKey", "${var.athena-output-encryption-kms-key}",
        "periodInDays", "${var.cert-rotation-period-in-days}"
      ),
      local.namedQueryMap,
      local.outputPathMap
      )}"
  }
  depends_on = [
    "aws_athena_named_query.ak-rotation-period",
    "aws_athena_named_query.ak-usage-period",
    "aws_athena_named_query.cert-rotation-period",
    "aws_athena_named_query.cred-usage-period"
  ]
}

# Lambda function that creates findings from the generated credentials report
resource "aws_lambda_function" "generate-findings_cred-usage-period" {
  filename         = "${data.archive_file.generate-findings.output_path}"
  function_name    = "credentials-tracker-generate-findings_cred-usage-period"
  role             = "${aws_iam_role.execution-role.arn}"
  handler          = "generate-findings.lambda_handler"
  source_code_hash = "${base64sha256(file(data.archive_file.generate-findings.output_path))}"
  runtime          = "python3.6"
  timeout          = 60
  environment{
    variables = "${merge(
      map(
        "namedQuery", "credUsagePeriod",
        "bucketName", "${local.environment-bucket-name}",
        "encryptionOption", "${var.athena-output-encryption-option}",
        "kmsKey", "${var.athena-output-encryption-kms-key}",
        "periodInDays", "${var.cred-usage-period-in-days}"
      ),
      local.namedQueryMap,
      local.outputPathMap
      )}"
  }
  depends_on = [
    "aws_athena_named_query.ak-rotation-period",
    "aws_athena_named_query.ak-usage-period",
    "aws_athena_named_query.cert-rotation-period",
    "aws_athena_named_query.cred-usage-period"
  ]
}

resource "aws_lambda_function" "retrieve-users-to-remediate" {
  filename         = "${data.archive_file.retrieve-users-to-remediate.output_path}"
  function_name    = "credentials-tracker-retrieve-users-to-remediate"
  role             = "${aws_iam_role.execution-role.arn}"
  handler          = "retrieve-users-to-remediate.lambda_handler"
  source_code_hash = "${base64sha256(file(data.archive_file.retrieve-users-to-remediate.output_path))}"
  runtime          = "python3.6"
  timeout          = 60
}

resource "aws_lambda_function" "remediate-findings_ak-rotation-period" {
  filename         = "${data.archive_file.remediate-findings_ak-rotation.output_path}"
  function_name    = "credentials-tracker-remediate-findings_ak-rotation"
  role             = "${aws_iam_role.execution-role.arn}"
  handler          = "remediate-findings_ak-rotation.lambda_handler"
  source_code_hash = "${base64sha256(file(data.archive_file.remediate-findings_ak-rotation.output_path))}"
  runtime          = "python3.6"
  timeout          = 60
  environment{
    variables = {
      periodInDays = "${var.ak-rotation-period-in-days}"
    }
  }
}

resource "aws_lambda_function" "remediate-findings_ak-usage-period" {
  filename         = "${data.archive_file.remediate-findings_ak-usage.output_path}"
  function_name    = "credentials-tracker-remediate-findings_ak-usage"
  role             = "${aws_iam_role.execution-role.arn}"
  handler          = "remediate-findings_ak-usage.lambda_handler"
  source_code_hash = "${base64sha256(file(data.archive_file.remediate-findings_ak-usage.output_path))}"
  runtime          = "python3.6"
  timeout          = 60
  environment{
    variables = {
      periodInDays = "${var.ak-usage-period-in-days}"
    }
  }
}

resource "aws_lambda_function" "remediate-findings_cert-rotation-period" {
  filename         = "${data.archive_file.remediate-findings_cert-rotation.output_path}"
  function_name    = "credentials-tracker-remediate-findings_cert-rotation"
  role             = "${aws_iam_role.execution-role.arn}"
  handler          = "remediate-findings_cert-rotation.lambda_handler"
  source_code_hash = "${base64sha256(file(data.archive_file.remediate-findings_cert-rotation.output_path))}"
  runtime          = "python3.6"
  timeout          = 60
  environment{
    variables = {
      periodInDays = "${var.cert-rotation-period-in-days}"
    }
  }
}

resource "aws_lambda_function" "remediate-findings_cred-usage-period" {
  filename         = "${data.archive_file.remediate-findings_cred-usage.output_path}"
  function_name    = "credentials-tracker-remediate-findings_cred-usage"
  role             = "${aws_iam_role.execution-role.arn}"
  handler          = "remediate-findings_cred-usage.lambda_handler"
  source_code_hash = "${base64sha256(file(data.archive_file.remediate-findings_cred-usage.output_path))}"
  runtime          = "python3.6"
  timeout          = 60
  environment{
    variables = {
      periodInDays = "${var.cred-usage-period-in-days}"
    }
  }
}
##--> Lambda Functions

##<-- Step Functions
# State Machine template used to generate the Step Functions definition
data "template_file" "state-machine" {
  template = "${file("./state-machines/credentials-tracker.json.tpl")}"

  vars {
    generate-report-lambda-arn = "${aws_lambda_function.generate-report.arn}"
    download-report-lambda-arn = "${aws_lambda_function.download-report.arn}"
    initialise-report-lambda-arn = "${aws_lambda_function.initialise-report.arn}"
    generate-findings_ak-usage-period-lambda-arn = "${aws_lambda_function.generate-findings_ak-usage-period.arn}"
    generate-findings_cred-usage-period-lambda-arn = "${aws_lambda_function.generate-findings_cred-usage-period.arn}"
    generate-findings_ak-rotation-period-lambda-arn = "${aws_lambda_function.generate-findings_ak-rotation-period.arn}"
    generate-findings_cert-rotation-period-lambda-arn = "${aws_lambda_function.generate-findings_cert-rotation-period.arn}"
    retrieve-users-to-remediate-lambda-arn = "${aws_lambda_function.retrieve-users-to-remediate.arn}"
    remediate-findings_ak-usage-period-lambda-arn = "${aws_lambda_function.remediate-findings_ak-usage-period.arn}"
    remediate-findings_cred-usage-period-lambda-arn = "${aws_lambda_function.remediate-findings_cred-usage-period.arn}"
    remediate-findings_ak-rotation-period-lambda-arn = "${aws_lambda_function.remediate-findings_ak-rotation-period.arn}"
    remediate-findings_cert-rotation-period-lambda-arn = "${aws_lambda_function.remediate-findings_cert-rotation-period.arn}"
  }
}

# Step Function State Machine that orchestrates the Credential Tracker Lambda functions
resource "aws_sfn_state_machine" "credentials-tracker" {
  name     = "credentials-tracker"
  role_arn = "${aws_iam_role.execution-role.arn}"
  definition = "${data.template_file.state-machine.rendered}"
}
##--> Step Functions

##<-- CloudWatch
# CloudWatch rule that initiates the Credentials Tracker Step Function
resource "aws_cloudwatch_event_rule" "initiator" {
  name        = "credentials-tracker-initiator"
  description = "Initiate a credentials report state machine"

  schedule_expression = "${var.credentials-tracker-schedule}"
}

# Target for te CloudWatch rule that initiates the Credentials Tracker Step Function
resource "aws_cloudwatch_event_target" "initiate-credential-tracker" {
  rule      = "${aws_cloudwatch_event_rule.initiator.name}"
  target_id = "SendToSF"
  role_arn = "${aws_iam_role.execution-role.arn}"
  arn       = "${aws_sfn_state_machine.credentials-tracker.id}"
}
##--> CloudWatch

##<-- Athena
locals {
  credentials-report-path = "${local.environment-bucket-name}/${var.credentials-tracker-prefix}"
  database-output-path = "${local.environment-bucket-name}/${var.database-output-prefix}"
}

resource "aws_athena_database" "secure-baseline-db" {
  name   = "secure_baseline_db"
  bucket = "${local.database-output-path}"
  depends_on = ["aws_s3_bucket.secure-baseline-bucket"]
}

data "template_file" "athena-table_credentials-report" {
  template = "${file("./athena/tables/credentials-report.hql.tpl")}"

  vars {
    database-name = "${aws_athena_database.secure-baseline-db.name}"
    table-name = "${var.credentials-report-name}"
    credentials-report-path = "${local.credentials-report-path}"
  }
}

resource "aws_athena_named_query" "credentials-report" {
  name     = "credentials-tracker_credentials-report-tb"
  database = "${aws_athena_database.secure-baseline-db.name}"
  query    = "${data.template_file.athena-table_credentials-report.rendered}"
  description = "DDL to create the credentials-report table"
}

data "template_file" "athena-table_partition-update" {
  template = "${file("./athena/tables/partition-update.hql.tpl")}"

  vars {
    database-name = "${aws_athena_database.secure-baseline-db.name}"
    table-name = "${var.credentials-report-name}"
  }
}

resource "aws_athena_named_query" "partition-update" {
  name     = "credentials-tracker_partition-update"
  database = "${aws_athena_database.secure-baseline-db.name}"
  query    = "${data.template_file.athena-table_partition-update.rendered}"
  description = "Statement to update the partitions in the credentials report"
}

data "template_file" "athena-query_ak-rotation-period" {
  template = "${file("./athena/queries/ak-rotation-period.hql.tpl")}"

  vars {
    database-name = "${aws_athena_database.secure-baseline-db.name}"
    table-name = "${var.credentials-report-name}"
  }
}

resource "aws_athena_named_query" "ak-rotation-period" {
  name     = "credentials-tracker_ak-rotation-period"
  database = "${aws_athena_database.secure-baseline-db.name}"
  query    = "${data.template_file.athena-query_ak-rotation-period.rendered}"
  description = "Query to check access key 1 rotation period exceptions"
}

data "template_file" "athena-query_ak-usage-period" {
  template = "${file("./athena/queries/ak-usage-period.hql.tpl")}"

  vars {
    database-name = "${aws_athena_database.secure-baseline-db.name}"
    table-name = "${var.credentials-report-name}"
  }
}

resource "aws_athena_named_query" "ak-usage-period" {
  name     = "credentials-tracker_ak-usage-period"
  database = "${aws_athena_database.secure-baseline-db.name}"
  query    = "${data.template_file.athena-query_ak-usage-period.rendered}"
  description = "Query to check access key 1 usage period exceptions"
}

data "template_file" "athena-query_cert-rotation-period" {
  template = "${file("./athena/queries/cert-rotation-period.hql.tpl")}"

  vars {
    database-name = "${aws_athena_database.secure-baseline-db.name}"
    table-name = "${var.credentials-report-name}"
  }
}

resource "aws_athena_named_query" "cert-rotation-period" {
  name     = "credentials-tracker_cert-rotation-period"
  database = "${aws_athena_database.secure-baseline-db.name}"
  query    = "${data.template_file.athena-query_cert-rotation-period.rendered}"
  description = "Query to check access certificate 1 rotation period exceptions"
}

data "template_file" "athena-query_cred-usage-period" {
  template = "${file("./athena/queries/cred-usage-period.hql.tpl")}"

  vars {
    database-name = "${aws_athena_database.secure-baseline-db.name}"
    table-name = "${var.credentials-report-name}"
  }
}

resource "aws_athena_named_query" "cred-usage-period" {
  name     = "credentials-tracker_cred-usage-period"
  database = "${aws_athena_database.secure-baseline-db.name}"
  query    = "${data.template_file.athena-query_cred-usage-period.rendered}"
  description = "Query to check console credentials rotation period exceptions"
}
##--> Athena
