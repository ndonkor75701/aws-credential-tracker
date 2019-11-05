# Generate local maps of query ID's and output paths for use in Lambda functions
/*
Currently Step Functions cannot refer to the step being executed in the Lambda
context.  The Lambda function code has been written to support this
functionality, however it has currently been implemented with a duplicate of the
Lambda function for each named query with a hard coded value passed for the
 relevant named query to execute from the map.
*/

# Lambda function that generates the credentials report
resource "aws_lambda_function" "generate-report" {
  filename         = data.archive_file.generate-report.output_path
  function_name    = "credentials-tracker-generate-report"
  role             = aws_iam_role.execution-role.arn
  handler          = "generate-report.lambda_handler"
  source_code_hash = filebase64sha256(data.archive_file.generate-report.output_path)
  runtime          = "python3.6"
  timeout          = 10
  environment {
    variables = {
      generateWaitTime = var.credential-report-generation-wait-time
    }
  }
}

# Lambda function that checks status and downloads the credentials report
resource "aws_lambda_function" "download-report" {
  filename         = data.archive_file.download-report.output_path
  function_name    = "credentials-tracker-download-report"
  role             = aws_iam_role.execution-role.arn
  handler          = "download-report.lambda_handler"
  source_code_hash = filebase64sha256(data.archive_file.download-report.output_path)
  runtime          = "python3.6"
  timeout          = 60
  environment {
    variables = {
      bucketName = local.environment-bucket-name
      prefix     = var.credentials-tracker-prefix
      fileName   = "report.csv"
    }
  }
}

# Lambda function that processes the credentials report and creates findings
resource "aws_lambda_function" "initialise-report" {
  filename         = data.archive_file.initialise-report.output_path
  function_name    = "credentials-tracker-initialise-report"
  role             = aws_iam_role.execution-role.arn
  handler          = "initialise-report.lambda_handler"
  source_code_hash = filebase64sha256(data.archive_file.initialise-report.output_path)
  runtime          = "python3.6"
  timeout          = 60
  environment {
    variables = {
      bucketName                  = local.environment-bucket-name
      credentialsReport           = aws_athena_named_query.credentials-report.id
      repairCredentialReport      = aws_athena_named_query.partition-update.id
      credentialsReportOutputPath = var.credentials-report-output-path
      encryptionOption            = var.athena-output-encryption-option
      kmsKey                      = var.athena-output-encryption-kms-key
    }
  }
  depends_on = [
    aws_athena_named_query.credentials-report,
    aws_athena_named_query.partition-update,
  ]
}

# Lambda function that creates findings from the generated credentials report
resource "aws_lambda_function" "generate-findings_ak-rotation-period" {
  filename         = data.archive_file.generate-findings.output_path
  function_name    = "credentials-tracker-generate-findings_ak-rotation-period"
  role             = aws_iam_role.execution-role.arn
  handler          = "generate-findings.lambda_handler"
  source_code_hash = filebase64sha256(data.archive_file.generate-findings.output_path)
  runtime          = "python3.6"
  timeout          = 60
  environment {
    variables = merge(
      {
        "namedQuery"       = "akRotationPeriod"
        "bucketName"       = local.environment-bucket-name
        "encryptionOption" = var.athena-output-encryption-option
        "kmsKey"           = var.athena-output-encryption-kms-key
        "periodInDays"     = var.ak-rotation-period-in-days
      },
      local.namedQueryMap,
      local.outputPathMap,
    )
  }
  depends_on = [
    aws_athena_named_query.ak-rotation-period,
    aws_athena_named_query.ak-usage-period,
    aws_athena_named_query.cert-rotation-period,
    aws_athena_named_query.cred-usage-period,
  ]
}

# Lambda function that creates findings from the generated credentials report
resource "aws_lambda_function" "generate-findings_ak-usage-period" {
  filename         = data.archive_file.generate-findings.output_path
  function_name    = "credentials-tracker-generate-findings_ak-usage-period"
  role             = aws_iam_role.execution-role.arn
  handler          = "generate-findings.lambda_handler"
  source_code_hash = filebase64sha256(data.archive_file.generate-findings.output_path)
  runtime          = "python3.6"
  timeout          = 60
  environment {
    variables = merge(
      {
        "namedQuery"       = "akUsagePeriod"
        "bucketName"       = local.environment-bucket-name
        "encryptionOption" = var.athena-output-encryption-option
        "kmsKey"           = var.athena-output-encryption-kms-key
        "periodInDays"     = var.ak-usage-period-in-days
      },
      local.namedQueryMap,
      local.outputPathMap,
    )
  }
  depends_on = [
    aws_athena_named_query.ak-rotation-period,
    aws_athena_named_query.ak-usage-period,
    aws_athena_named_query.cert-rotation-period,
    aws_athena_named_query.cred-usage-period,
  ]
}

# Lambda function that creates findings from the generated credentials report
resource "aws_lambda_function" "generate-findings_cert-rotation-period" {
  filename         = data.archive_file.generate-findings.output_path
  function_name    = "credentials-tracker-generate-findingscert-rotation-period"
  role             = aws_iam_role.execution-role.arn
  handler          = "generate-findings.lambda_handler"
  source_code_hash = filebase64sha256(data.archive_file.generate-findings.output_path)
  runtime          = "python3.6"
  timeout          = 60
  environment {
    variables = merge(
      {
        "namedQuery"       = "certRotationPeriod"
        "bucketName"       = local.environment-bucket-name
        "encryptionOption" = var.athena-output-encryption-option
        "kmsKey"           = var.athena-output-encryption-kms-key
        "periodInDays"     = var.cert-rotation-period-in-days
      },
      local.namedQueryMap,
      local.outputPathMap,
    )
  }
  depends_on = [
    aws_athena_named_query.ak-rotation-period,
    aws_athena_named_query.ak-usage-period,
    aws_athena_named_query.cert-rotation-period,
    aws_athena_named_query.cred-usage-period,
  ]
}

# Lambda function that creates findings from the generated credentials report
resource "aws_lambda_function" "generate-findings_cred-usage-period" {
  filename         = data.archive_file.generate-findings.output_path
  function_name    = "credentials-tracker-generate-findings_cred-usage-period"
  role             = aws_iam_role.execution-role.arn
  handler          = "generate-findings.lambda_handler"
  source_code_hash = filebase64sha256(data.archive_file.generate-findings.output_path)
  runtime          = "python3.6"
  timeout          = 60
  environment {
    variables = merge(
      {
        "namedQuery"       = "credUsagePeriod"
        "bucketName"       = local.environment-bucket-name
        "encryptionOption" = var.athena-output-encryption-option
        "kmsKey"           = var.athena-output-encryption-kms-key
        "periodInDays"     = var.cred-usage-period-in-days
      },
      local.namedQueryMap,
      local.outputPathMap,
    )
  }
  depends_on = [
    aws_athena_named_query.ak-rotation-period,
    aws_athena_named_query.ak-usage-period,
    aws_athena_named_query.cert-rotation-period,
    aws_athena_named_query.cred-usage-period,
  ]
}

resource "aws_lambda_function" "retrieve-users-to-remediate" {
  filename         = data.archive_file.retrieve-users-to-remediate.output_path
  function_name    = "credentials-tracker-retrieve-users-to-remediate"
  role             = aws_iam_role.execution-role.arn
  handler          = "retrieve-users-to-remediate.lambda_handler"
  source_code_hash = filebase64sha256(data.archive_file.retrieve-users-to-remediate.output_path)
  runtime          = "python3.6"
  timeout          = 60
}

resource "aws_lambda_function" "remediate-findings_ak-rotation-period" {
  filename         = data.archive_file.remediate-findings_ak-rotation.output_path
  function_name    = "credentials-tracker-remediate-findings_ak-rotation"
  role             = aws_iam_role.execution-role.arn
  handler          = "remediate-findings_ak-rotation.lambda_handler"
  source_code_hash = filebase64sha256(data.archive_file.remediate-findings_ak-rotation.output_path)
  runtime          = "python3.6"
  timeout          = 60
  environment {
    variables = {
      periodInDays = var.ak-rotation-period-in-days
    }
  }
}

resource "aws_lambda_function" "remediate-findings_ak-usage-period" {
  filename         = data.archive_file.remediate-findings_ak-usage.output_path
  function_name    = "credentials-tracker-remediate-findings_ak-usage"
  role             = aws_iam_role.execution-role.arn
  handler          = "remediate-findings_ak-usage.lambda_handler"
  source_code_hash = filebase64sha256(data.archive_file.remediate-findings_ak-usage.output_path)
  runtime          = "python3.6"
  timeout          = 60
  environment {
    variables = {
      periodInDays = var.ak-usage-period-in-days
    }
  }
}

resource "aws_lambda_function" "remediate-findings_cert-rotation-period" {
  filename      = data.archive_file.remediate-findings_cert-rotation.output_path
  function_name = "credentials-tracker-remediate-findings_cert-rotation"
  role          = aws_iam_role.execution-role.arn
  handler       = "remediate-findings_cert-rotation.lambda_handler"
  source_code_hash = filebase64sha256(
    data.archive_file.remediate-findings_cert-rotation.output_path,
  )
  runtime = "python3.6"
  timeout = 60
  environment {
    variables = {
      periodInDays = var.cert-rotation-period-in-days
    }
  }
}

resource "aws_lambda_function" "remediate-findings_cred-usage-period" {
  filename         = data.archive_file.remediate-findings_cred-usage.output_path
  function_name    = "credentials-tracker-remediate-findings_cred-usage"
  role             = aws_iam_role.execution-role.arn
  handler          = "remediate-findings_cred-usage.lambda_handler"
  source_code_hash = filebase64sha256(data.archive_file.remediate-findings_cred-usage.output_path)
  runtime          = "python3.6"
  timeout          = 60
  environment {
    variables = {
      periodInDays = var.cred-usage-period-in-days
    }
  }
}