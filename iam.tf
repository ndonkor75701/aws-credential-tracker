# IAM Role for Lambda executions made by the Credentials Tracker
resource "aws_iam_role" "execution-role" {
  name               = "credentialsTracker-execution-role"
  assume_role_policy = file("./policies/lambda-trust.json")
}

# Assume role trust policy for the Credentials Tracker execution role
resource "aws_iam_policy" "lambda-execution" {
  name        = "credentials-tracker-execution-policy"
  description = "Credentials Tracker execution policy"
  policy      = data.template_file.lambda-execution-policy.rendered
}

# Attached execution policy for the Credentials Tracker execution role
resource "aws_iam_role_policy_attachment" "policy-attach" {
  role       = aws_iam_role.execution-role.name
  policy_arn = aws_iam_policy.lambda-execution.arn
}