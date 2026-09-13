resource "aws_lambda_function" "gateway" {
  function_name    = "llm-gateway"
  role             = aws_iam_role.gateway_lambda.arn
  handler          = "gateway.handler"
  runtime          = "python3.14"
  filename         = "${path.module}/../lambda/gateway.zip"
  source_code_hash = filebase64sha256("${path.module}/../lambda/gateway.zip")
  timeout          = 15

  environment {
    variables = {
      PYTHONUNBUFFERED = "1"
    }
  }
}