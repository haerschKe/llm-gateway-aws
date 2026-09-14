resource "aws_lambda_function" "gateway" {
  function_name    = "llm-gateway"
  role             = aws_iam_role.gateway_lambda.arn
  handler          = "gateway.handler"
  runtime          = var.lambda_runtime
  filename         = "${path.module}/../lambda/gateway.zip"
  source_code_hash = filebase64sha256("${path.module}/../lambda/gateway.zip")
  timeout          = var.gateway_lambda_timeout

  environment {
    variables = {
      # Forces unbuffered stdout/stderr - otherwise print() output can be
      # lost before the container process exits.
      PYTHONUNBUFFERED  = "1"
      REQUEST_LOG_TABLE = var.request_log_table_name
      CACHE_TABLE       = var.cache_table_name
      CACHE_TTL_SECONDS = tostring(var.cache_ttl_seconds)
      DEFAULT_MODEL_ID  = var.default_model_id
    }
  }
}

resource "aws_lambda_function" "authorizer" {
  function_name    = "llm-gateway-authorizer"
  role             = aws_iam_role.authorizer_lambda.arn
  handler          = "authorizer.handler"
  runtime          = var.lambda_runtime
  filename         = "${path.module}/../lambda/authorizer.zip"
  source_code_hash = filebase64sha256("${path.module}/../lambda/authorizer.zip")
  timeout          = var.authorizer_lambda_timeout

  environment {
    variables = {
      PYTHONUNBUFFERED  = "1"
      API_KEYS_TABLE    = var.api_keys_table_name
      RATE_LIMITS_TABLE = var.rate_limits_table_name
    }
  }
}