locals {
  environment-bucket-name = "${var.environment-name}-${var.aws-account-number}"
  
  credentials-report-path = "${local.environment-bucket-name}/${var.credentials-tracker-prefix}"
  
  database-output-path    = "${local.environment-bucket-name}/${var.database-output-prefix}"
  
  namedQueryMap = {
    akRotationPeriod   = aws_athena_named_query.ak-rotation-period.id
    akUsagePeriod      = aws_athena_named_query.ak-usage-period.id
    certRotationPeriod = aws_athena_named_query.cert-rotation-period.id
    credUsagePeriod    = aws_athena_named_query.cred-usage-period.id
  }
  
  outputPathMap = {
    akRotationPeriodOutputPath   = var.ak-rotation-period-output-path
    akUsagePeriodOutputPath      = var.ak-usage-period-output-path
    certRotationPeriodOutputPath = var.cred-usage-period-output-path
    credUsagePeriodOutputPath    = var.cred-usage-period-output-path
  }
}