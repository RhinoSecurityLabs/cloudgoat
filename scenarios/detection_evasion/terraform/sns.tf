# does the resource below need a a detailed delivery policy for any reason? Might be worth looking into.
resource "aws_sns_topic" "honeytoken_detected" {
  name = "phase1"
}

resource "aws_sns_topic_subscription" "honeytoken_subscription" {
  topic_arn = aws_sns_topic.honeytoken_detected.arn
  protocol  = "email"
  endpoint  = var.user_email
}

resource "aws_sns_topic" "instance_profile_abnormally_used" {
  name = "phase2"
}

resource "aws_sns_topic_subscription" "instance_profile_subscription" {
  topic_arn = aws_sns_topic.instance_profile_abnormally_used.arn
  protocol  = "email"
  endpoint  = var.user_email
}