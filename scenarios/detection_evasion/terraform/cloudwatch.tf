resource "aws_cloudwatch_log_group" "honeytoken_logs" {
  name = "honeytoken_logs"
}

# below is the filter which will detect events
resource "aws_cloudwatch_log_metric_filter" "honeytoken_logs" {
  name           = "HoneyTokenUsed"
  pattern        = "{ $.userIdentity.arn = \"${aws_iam_user.spacesiren_user.arn}\" || $.userIdentity.arn = \"${aws_iam_user.canarytoken_user.arn}\" || $.userIdentity.arn = \"${aws_iam_user.spacecrab_user.arn}\" }"
  log_group_name = "${aws_cloudwatch_log_group.honeytoken_logs.name}"

  metric_transformation {
    name      = "honeytoken_used"
    namespace = "cloudgoat_detection_evasion"
    value     = "1"
  }
}

// #below is the alert which specifies the event threshold
resource "aws_cloudwatch_metric_alarm" "foobar" {
  alarm_name                = "honeytoken_alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "honeytoken_used"
  namespace                 = "cloudgoat_detection_evasion"
  period                    = "60"
  statistic                 = "Sum"
  threshold                 = "1"
  alarm_description         = "This metric monitors the usage of honeytokens"
  insufficient_data_actions = []
  actions_enabled = "true"
  alarm_actions = ["arn:aws:sns:us-east-1:940877411605:honeytoken-detected"]
}