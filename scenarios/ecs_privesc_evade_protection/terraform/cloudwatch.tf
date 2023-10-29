# Define a CloudWatch Event Rule to capture AWS GuardDuty findings
resource "aws_cloudwatch_event_rule" "guardduty_events" {
  name        = "cg-guardduty-events-${var.cgid}"
  event_pattern = jsonencode({
    "source" : ["aws.guardduty"],
    "detail-type" : ["GuardDuty Finding"],
    "detail": {
      "type": [
        "UnauthorizedAccess:IAMUser/InstanceCredentialExfiltration.OutsideAWS",
      ]
    }
  })
}

# Create a target for the CloudWatch Event Rule to invoke a Lambda function
resource "aws_cloudwatch_event_target" "ecs_event_target" {
  rule = aws_cloudwatch_event_rule.guardduty_events.name
  arn  = aws_lambda_function.guardduty_lambda.arn
}

# Enable AWS GuardDuty for threat detection and continuous monitoring
# Note : The GuardDuty in the user account must be completely disabled to function normally.
resource "aws_guardduty_detector" "detector" {
  enable = true
}