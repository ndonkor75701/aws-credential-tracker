# Step Function State Machine that orchestrates the Credential Tracker Lambda functions
resource "aws_sfn_state_machine" "credentials-tracker" {
  name       = "credentials-tracker"
  role_arn   = aws_iam_role.execution-role.arn
  definition = data.template_file.state-machine.rendered
}