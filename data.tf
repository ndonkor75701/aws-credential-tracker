data "template_file" "lambda-execution-policy" {
  template = file("./policies/lambda-execution.json.tpl")

  vars = {
    bucket-name                                        = local.environment-bucket-name
    generate-report-lambda-arn                         = aws_lambda_function.generate-report.arn
    download-report-lambda-arn                         = aws_lambda_function.download-report.arn
    initialise-report-lambda-arn                       = aws_lambda_function.initialise-report.arn
    generate-findings_ak-usage-period-lambda-arn       = aws_lambda_function.generate-findings_ak-usage-period.arn
    generate-findings_cred-usage-period-lambda-arn     = aws_lambda_function.generate-findings_cred-usage-period.arn
    generate-findings_ak-rotation-period-lambda-arn    = aws_lambda_function.generate-findings_ak-rotation-period.arn
    generate-findings_cert-rotation-period-lambda-arn  = aws_lambda_function.generate-findings_cert-rotation-period.arn
    retrieve-users-to-remediate-lambda-arn             = aws_lambda_function.retrieve-users-to-remediate.arn
    remediate-findings_ak-usage-period-lambda-arn      = aws_lambda_function.remediate-findings_ak-usage-period.arn
    remediate-findings_cred-usage-period-lambda-arn    = aws_lambda_function.remediate-findings_cred-usage-period.arn
    remediate-findings_ak-rotation-period-lambda-arn   = aws_lambda_function.remediate-findings_ak-rotation-period.arn
    remediate-findings_cert-rotation-period-lambda-arn = aws_lambda_function.remediate-findings_cert-rotation-period.arn
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

# State Machine template used to generate the Step Functions definition
data "template_file" "state-machine" {
  template = file("./state-machines/credentials-tracker.json.tpl")

  vars = {
    generate-report-lambda-arn                         = aws_lambda_function.generate-report.arn
    download-report-lambda-arn                         = aws_lambda_function.download-report.arn
    initialise-report-lambda-arn                       = aws_lambda_function.initialise-report.arn
    generate-findings_ak-usage-period-lambda-arn       = aws_lambda_function.generate-findings_ak-usage-period.arn
    generate-findings_cred-usage-period-lambda-arn     = aws_lambda_function.generate-findings_cred-usage-period.arn
    generate-findings_ak-rotation-period-lambda-arn    = aws_lambda_function.generate-findings_ak-rotation-period.arn
    generate-findings_cert-rotation-period-lambda-arn  = aws_lambda_function.generate-findings_cert-rotation-period.arn
    retrieve-users-to-remediate-lambda-arn             = aws_lambda_function.retrieve-users-to-remediate.arn
    remediate-findings_ak-usage-period-lambda-arn      = aws_lambda_function.remediate-findings_ak-usage-period.arn
    remediate-findings_cred-usage-period-lambda-arn    = aws_lambda_function.remediate-findings_cred-usage-period.arn
    remediate-findings_ak-rotation-period-lambda-arn   = aws_lambda_function.remediate-findings_ak-rotation-period.arn
    remediate-findings_cert-rotation-period-lambda-arn = aws_lambda_function.remediate-findings_cert-rotation-period.arn
  }
}

data "template_file" "athena-table_credentials-report" {
  template = file("./athena/tables/credentials-report.hql.tpl")

  vars = {
    database-name           = aws_athena_database.secure-baseline-db.name
    table-name              = var.credentials-report-name
    credentials-report-path = local.credentials-report-path
  }
}

data "template_file" "athena-table_partition-update" {
  template = file("./athena/tables/partition-update.hql.tpl")

  vars = {
    database-name = aws_athena_database.secure-baseline-db.name
    table-name    = var.credentials-report-name
  }
}

data "template_file" "athena-query_ak-rotation-period" {
  template = file("./athena/queries/ak-rotation-period.hql.tpl")

  vars = {
    database-name = aws_athena_database.secure-baseline-db.name
    table-name    = var.credentials-report-name
  }
}

data "template_file" "athena-query_ak-usage-period" {
  template = file("./athena/queries/ak-usage-period.hql.tpl")

  vars = {
    database-name = aws_athena_database.secure-baseline-db.name
    table-name    = var.credentials-report-name
  }
}

data "template_file" "athena-query_cert-rotation-period" {
  template = file("./athena/queries/cert-rotation-period.hql.tpl")

  vars = {
    database-name = aws_athena_database.secure-baseline-db.name
    table-name    = var.credentials-report-name
  }
}

data "template_file" "athena-query_cred-usage-period" {
  template = file("./athena/queries/cred-usage-period.hql.tpl")

  vars = {
    database-name = aws_athena_database.secure-baseline-db.name
    table-name    = var.credentials-report-name
  }
}