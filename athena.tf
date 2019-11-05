resource "aws_athena_database" "secure-baseline-db" {
  name       = "secure_baseline_db"
  bucket     = local.database-output-path
  depends_on = [aws_s3_bucket.secure-baseline-bucket]
}

resource "aws_athena_named_query" "credentials-report" {
  name        = "credentials-tracker_credentials-report-tb"
  database    = aws_athena_database.secure-baseline-db.name
  query       = data.template_file.athena-table_credentials-report.rendered
  description = "DDL to create the credentials-report table"
}

resource "aws_athena_named_query" "partition-update" {
  name        = "credentials-tracker_partition-update"
  database    = aws_athena_database.secure-baseline-db.name
  query       = data.template_file.athena-table_partition-update.rendered
  description = "Statement to update the partitions in the credentials report"
}

resource "aws_athena_named_query" "ak-rotation-period" {
  name        = "credentials-tracker_ak-rotation-period"
  database    = aws_athena_database.secure-baseline-db.name
  query       = data.template_file.athena-query_ak-rotation-period.rendered
  description = "Query to check access key 1 rotation period exceptions"
}

resource "aws_athena_named_query" "ak-usage-period" {
  name        = "credentials-tracker_ak-usage-period"
  database    = aws_athena_database.secure-baseline-db.name
  query       = data.template_file.athena-query_ak-usage-period.rendered
  description = "Query to check access key 1 usage period exceptions"
}

resource "aws_athena_named_query" "cert-rotation-period" {
  name        = "credentials-tracker_cert-rotation-period"
  database    = aws_athena_database.secure-baseline-db.name
  query       = data.template_file.athena-query_cert-rotation-period.rendered
  description = "Query to check access certificate 1 rotation period exceptions"
}

resource "aws_athena_named_query" "cred-usage-period" {
  name        = "credentials-tracker_cred-usage-period"
  database    = aws_athena_database.secure-baseline-db.name
  query       = data.template_file.athena-query_cred-usage-period.rendered
  description = "Query to check console credentials rotation period exceptions"
}