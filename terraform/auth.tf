# IAM role for the authorizer - its own role, its own minimal permissions
data "aws_iam_policy_document" "authorizer_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "authorizer_lambda" {
  name               = "llm-gateway-authorizer-role"
  assume_role_policy = data.aws_iam_policy_document.authorizer_assume.json
}

data "aws_iam_policy_document" "authorizer_dynamodb" {
  statement {
    actions   = ["dynamodb:GetItem"]
    resources = [aws_dynamodb_table.api_keys.arn]
  }
  statement {
    actions   = ["dynamodb:UpdateItem"]
    resources = [aws_dynamodb_table.rate_limits.arn]
  }
}

resource "aws_iam_role_policy" "authorizer_dynamodb_access" {
  name   = "dynamodb-access"
  role   = aws_iam_role.authorizer_lambda.id
  policy = data.aws_iam_policy_document.authorizer_dynamodb.json
}

resource "aws_lambda_function" "authorizer" {
  function_name    = "llm-gateway-authorizer"
  role             = aws_iam_role.authorizer_lambda.arn
  handler          = "authorizer.handler"
  runtime          = "python3.14"
  filename         = "${path.module}/../lambda/authorizer.zip"
  source_code_hash = filebase64sha256("${path.module}/../lambda/authorizer.zip")
  timeout          = 5

  environment {
    variables = {
      PYTHONUNBUFFERED = "1"
    }
  }
}

resource "aws_apigatewayv2_authorizer" "api_key_auth" {
  api_id                            = aws_apigatewayv2_api.gateway.id
  authorizer_type                   = "REQUEST"
  authorizer_uri                    = aws_lambda_function.authorizer.invoke_arn
  identity_sources                  = ["$request.header.x-api-key"]
  name                              = "api-key-authorizer"
  authorizer_payload_format_version = "2.0"
  # enable_simple_responses allows the lightweight {"isAuthorized": true/false}
  # format instead of the more complex IAM policy response.
  enable_simple_responses = true
}

resource "aws_lambda_permission" "authorizer_apigw" {
  statement_id  = "AllowAPIGatewayInvokeAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.authorizer.function_name
  principal     = "apigateway.amazonaws.com"
}