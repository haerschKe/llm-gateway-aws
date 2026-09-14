output "api_id" {
  description = "API ID - needed for local invocation against floci"
  value       = aws_apigatewayv2_api.gateway.id
}

output "api_endpoint" {
  description = "Invoke URL as returned by AWS/floci - looks like real AWS but is NOT directly reachable locally (see README for the local invocation workaround)"
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "chat_endpoint" {
  description = "Full /v1/chat URL in AWS format - for local invocation, see README workaround instead of calling this directly"
  value       = "${trimsuffix(aws_apigatewayv2_stage.default.invoke_url, "/")}/v1/chat"
}