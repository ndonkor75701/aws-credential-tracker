# CloudWatch rule that initiates the Credentials Tracker Step Function
resource "aws_cloudwatch_event_rule" "initiator" {
  name        = "credentials-tracker-initiator"
  description = "Initiate a credentials report state machine"

  schedule_expression = var.credentials-tracker-schedule
}

# Target for te CloudWatch rule that initiates the Credentials Tracker Step Function
resource "aws_cloudwatch_event_target" "initiate-credential-tracker" {
  rule      = aws_cloudwatch_event_rule.initiator.name
  target_id = "SendToSF"
  role_arn  = aws_iam_role.execution-role.arn
  arn       = aws_sfn_state_machine.credentials-tracker.id
}