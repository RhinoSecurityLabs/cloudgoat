
module "lambda_function_container_image" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = local.lambda_function_name

  create_package = false

  image_uri    = format("%s:latest", aws_ecr_repository.app.repository_url)
  package_type = "Image"

  depends_on = [null_resource.upload_files]
}


resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "AllowInvokeFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_function_container_image.lambda_function_name
  principal     = "apigateway.amazonaws.com"

  # The /*/*/* part allows invocation from any stage, method and resource path
  # within API Gateway REST API.
  source_arn = "${aws_apigatewayv2_api.apigw.execution_arn}/*/*/*"
}
