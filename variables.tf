variable "aws-account-number" {
  description = "The account number off the AWS account that the script is being in run against"
}

variable "event-subscription-email-address" {
  description = "The email address to send SNS events to."
}

variable "credentials-tracker-schedule" {
  description = "The defined schedule for the cloudwatch alarm to trigger"
  default = "cron(15 12 * * ? *)"
}

variable "environment-name" {
  description = "The name of the environment being deployed"
  default = "secure-baseline"
}

variable "athena-database-name" {
  description = "The name of the environment being deployed"
  default = "secure_baseline_db"
}

variable "credentials-tracker-prefix" {
  description = "The S3 prefix for the credentials report"
  default = "credentials-tracker/credentials-report/"
}

variable "database-output-prefix" {
  description = "The S3 prefix for the credentials report"
  default = "credentials-tracker/athena-output/general/"
}

variable "credentials-report-name" {
  description = "Name of the credentials report"
  default = "credentials-report"
}

variable "credential-report-generation-wait-time" {
  description = "The time (in seconds) to wait before attempting to download the report after the generation request"
  default = 10
}

variable "credentials-report-output-path" {
  description = "The S3 prefix for the credentials report output path"
  default = "credentials-tracker/athena-output/general/"
}

variable "ak-rotation-period-output-path" {
  description = "The S3 prefix for access key rotation findings"
  default = "credentials-tracker/athena-output/findings/access-key-rotation/"
}

variable "ak-usage-period-output-path" {
  description = "The S3 prefix for access key usage findings"
  default = "credentials-tracker/athena-output/findings/access-key-usage/"
}

variable "cert-rotation-period-output-path" {
  description = "The S3 prefix for certificate rotation findings"
  default = "credentials-tracker/athena-output/findings/certificate-rotation/"
}

variable "cred-usage-period-output-path" {
  description = "The S3 prefix for credentials usage findings"
  default = "credentials-tracker/athena-output/findings/credentials-usage/"
}

variable "athena-output-encryption-option" {
  description = "The encryption option for the query output"
  default = "NONE"
}

variable "athena-output-encryption-kms-key" {
  description = "The encryption key for the query output"
  default = "NONE"
}

variable "ak-rotation-period-in-days" {
  description = "Period in days for credential or access key"
  default = 90
}

variable "ak-usage-period-in-days" {
  description = "Period in days for credential or access key"
  default = 90
}

variable "cert-rotation-period-in-days" {
  description = "Period in days for credential or access key"
  default = 0
}

variable "cred-usage-period-in-days" {
  description = "Period in days for credential or access key"
  default = 90
}
