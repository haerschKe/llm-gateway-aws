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