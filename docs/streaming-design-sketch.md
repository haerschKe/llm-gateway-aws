# Streaming Responses — Design Sketch (Not Implemented)

## Why this isn't implemented

API Gateway **HTTP API v2** does not support native response streaming to the
client — every request through API Gateway is fully buffered: the complete
response is collected before anything is sent back. To actually stream, you'd
need **Lambda Function URLs** with `InvokeMode = RESPONSE_STREAM`, which is a
direct Lambda endpoint that bypasses API Gateway entirely — including the
Lambda authorizer built in Phase 3.

## What it would look like

```hcl
resource "aws_lambda_function_url" "gateway_streaming" {
  function_name      = aws_lambda_function.gateway.function_name
  authorization_type = "NONE" # Function URLs support IAM auth or none - our
                                # custom API-key authorizer from Phase 3 doesn't
                                # attach here; this would need its own auth
                                # check inside the handler.
  invoke_mode         = "RESPONSE_STREAM"
}
```

```python
# Pseudocode - actual response streaming in Python Lambda requires the Lambda
# Web Adapter or the runtime's streaming response helpers, which differ from
# the simple return-a-dict pattern used everywhere else in this project.
def handler(event, response_stream, context):
    ollama_stream = bedrock.converse_stream(modelId=model_id, messages=[...])
    for chunk in ollama_stream["stream"]:
        response_stream.write(chunk["contentBlockDelta"]["delta"]["text"])
    response_stream.end()
```

## Trade-offs

1. Function URLs with streaming support either `AWS_IAM` or no authorization
   at all — the Phase 3 Lambda authorizer would have to be reimplemented as
   plain logic *inside* the streaming handler (manually reading the header,
   manually calling DynamoDB), instead of being declaratively attached via
   `aws_apigatewayv2_authorizer`.
2. Two parallel entry points (API Gateway for normal calls, a Function URL
   for streaming) mean two maintenance paths for essentially the same use case.
3. Ollama itself supports streaming without any extra work (`stream: true` in
   the API call) — the bottleneck is entirely on the AWS side (API Gateway),
   not the model provider.

## Conclusion

Deliberately not implemented, since it would bypass the Phase 3 Lambda
authorizer. In a real production system, this would be solved with a
dedicated streaming route that has its own lightweight auth check.