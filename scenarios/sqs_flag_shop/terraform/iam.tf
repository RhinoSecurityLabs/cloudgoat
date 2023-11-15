resource "aws_iam_user" "cg-run-app" {
  name = "cg-run-app-${var.cgid}"
  tags = {
    Name     = "cg-run-app-${var.cgid}"
    Stack    = var.stack-name
    Scenario = var.scenario-name
  }
}


resource "aws_iam_access_key" "cg-run-app_access_key" {
  user = aws_iam_user.cg-run-app.name
}

resource "aws_iam_policy_attachment" "user_RDS_full_access" {
  name       = "RDSFullAccessAttachment"
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
  users      = [aws_iam_user.cg-run-app.name]
}

