output "api_id" {
  description = "API-ID - wird für den lokalen Aufruf gegen floci gebraucht"
  value       = aws_apigatewayv2_api.gateway.id
}

output "api_endpoint" {
  description = "Von AWS/floci zurückgegebene Invoke-URL - sieht aus wie echtes AWS, ist aber lokal NICHT direkt aufrufbar (siehe Hinweis unten)"
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "chat_endpoint" {
  description = "Vollständige URL der /v1/chat-Route im AWS-Format - für den lokalen Aufruf siehe Hinweis unten"
  value       = "${trimsuffix(aws_apigatewayv2_stage.default.invoke_url, "/")}/v1/chat"
}