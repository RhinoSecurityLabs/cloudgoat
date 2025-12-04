resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role_${var.cgid}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_execution_role_log_policy" {
  role   = aws_iam_role.lambda_execution_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.aws-account-id.account_id}:log-group:/aws/lambda/inventory_lambda_${var.cgid}:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_execution_role_policy_attach" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

data "archive_file" "inventory_lambda_zip" {
  type        = "zip"
  source_dir  = "lambda_source"
  output_path = "lambda_source.zip"
}

resource "aws_cloudwatch_log_group" "inventory_lambda_log_group" {
  name              = "/aws/lambda/inventory_lambda_${var.cgid}"
  retention_in_days = 14
}

resource "aws_lambda_function" "inventory_lambda" {
  depends_on = [
    aws_cloudwatch_log_group.inventory_lambda_log_group
  ]

  filename         = data.archive_file.inventory_lambda_zip.output_path
  function_name    = "inventory_lambda_${var.cgid}"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "main.handler"
  description      = "This function will perform an inventory on one of several resource types in AWS: IAM Roles, IAM Users, EC2 Instances, and S3 Buckets"
  source_code_hash = filebase64sha256(data.archive_file.inventory_lambda_zip.output_path)
  runtime          = "python3.9"
}

resource "aws_lambda_permission" "allow_agent_invokation" {
  statement_id  = "AllowAgent"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.inventory_lambda.function_name
  principal     = "bedrock.amazonaws.com"
  source_arn    = aws_bedrockagent_agent.operations_agent.agent_arn
}