resource "aws_cloudwatch_log_group" "main" {
  name = "cg_detection_evasion_logs"
  tags = {
    tag-key = var.cgid
  }
}

// Resources for detecting/alerting on honeytokens
resource "aws_cloudwatch_log_metric_filter" "honeytoken_is_used" {
  name           = "honeytoken_is_used"
  pattern        = "{ $.userIdentity.arn = \"${aws_iam_user.spacesiren_user.arn}\" || $.userIdentity.arn = \"${aws_iam_user.canarytoken_user.arn}\" || $.userIdentity.arn = \"${aws_iam_user.spacecrab_user.arn}\" }"
  log_group_name = aws_cloudwatch_log_group.main.name

  metric_transformation {
    name          = "honeytoken_is_used"
    namespace     = "cloudgoat_detection_evasion"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "honeytoken_alarm" {
  alarm_name          = "honeytoken_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  metric_name         = "honeytoken_is_used"
  namespace           = "cloudgoat_detection_evasion"

  period              = "60"
  evaluation_periods  = "1"
  threshold           = "1"
  datapoints_to_alarm = "1"

  statistic                 = "Sum"
  alarm_description         = "Alerts on the usage of honeytokens"
  insufficient_data_actions = []
  actions_enabled           = "true"
  alarm_actions             = [aws_sns_topic.honeytoken_detected.arn]
}

// resources for detecting/alerting on abnormal instance_profile usage
resource "aws_cloudwatch_log_metric_filter" "instance_profile_abnormal_usage" {
  name           = "instance_profile_abnormal_usage"
  pattern        = "{ (($.sourceIPAddress != \"${aws_instance.hard_path.private_ip}\") && ($.userIdentity.arn = \"arn:aws:sts::${data.aws_caller_identity.aws-account-id.account_id}:assumed-role/${aws_iam_role.ec2_instance_profile_role_hard_path.name}/${aws_instance.hard_path.id}\")) || (($.sourceIPAddress != \"${aws_instance.easy_path.public_ip}\") && ($.userIdentity.arn = \"arn:aws:sts::${data.aws_caller_identity.aws-account-id.account_id}:assumed-role/${aws_iam_role.ec2_instance_profile_role_easy_path.name}/${aws_instance.easy_path.id}\")) }"
  log_group_name = aws_cloudwatch_log_group.main.name

  metric_transformation {
    name          = "instance_profile_abnormal_usage"
    namespace     = "cloudgoat_detection_evasion"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "instance_profile_alarm" {
  alarm_name          = "instance_profile_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  metric_name         = "instance_profile_abnormal_usage"
  namespace           = "cloudgoat_detection_evasion"

  period              = "60"
  evaluation_periods  = "1"
  threshold           = "1"
  datapoints_to_alarm = "1"

  statistic                 = "Sum"
  alarm_description         = "Alarms on the usage of instance_profile credentials from an IP other than that of the ec2 instance associated with the profile."
  insufficient_data_actions = []
  actions_enabled           = "true"
  alarm_actions             = [aws_sns_topic.instance_profile_abnormally_used.arn]
}