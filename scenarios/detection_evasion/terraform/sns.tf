# does the resource below need a a detailed delivery policy for any reason? Might be worth looking into.
resource "aws_sns_topic" "honeytoken_detected" {
  name = "honeytoken-detected"
}

# the subscription below will need to fill out both the protocol and the protocol's details at deployment time via a user-supplied
# variable. 
resource "aws_sns_topic_subscription" "general_purpose_user_subscription" {
  topic_arn = "${aws_sns_topic.honeytoken_detected.arn}"
  protocol  = "email"
  endpoint  = var.user_email
}

