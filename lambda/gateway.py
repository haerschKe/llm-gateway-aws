import json
import sys
import base64
import time
import uuid
import traceback
import boto3

bedrock = boto3.client("bedrock-runtime")
dynamodb = boto3.client("dynamodb")

REQUEST_LOG_TABLE = "llm-gateway-requests"

# Fictional prices for illustrating the concept - not real Bedrock prices.
COST_PER_1K_INPUT_TOKENS = 0.00025
COST_PER_1K_OUTPUT_TOKENS = 0.00125


def handler(event, context):
    print("Handler invoked", flush=True)
    start_time = time.time()

    raw_body = event.get("body") or "{}"
    if event.get("isBase64Encoded"):
        raw_body = base64.b64decode(raw_body).decode("utf-8")

    body = json.loads(raw_body)
    prompt = body.get("prompt", "")
    model_id = body.get("modelId", "anthropic.claude-3-haiku-20240307-v1:0")

    # Prefer the API key from the context set by the authorizer (verified,
    # see Phase 3), falling back to the raw header - relevant e.g. if the
    # route is ever tested without the authorizer attached.
    api_key = (
        event.get("requestContext", {})
        .get("authorizer", {})
        .get("lambda", {})
        .get("apiKey")
        or event.get("headers", {}).get("x-api-key", "unknown")
    )

    if not prompt:
        return {"statusCode": 400, "body": json.dumps({"error": "prompt fehlt"})}

    try:
        response = bedrock.converse(
            modelId=model_id,
            messages=[{"role": "user", "content": [{"text": prompt}]}],
        )
    except Exception as e:
        print(f"Bedrock call failed: {e}", flush=True)
        traceback.print_exc(file=sys.stdout)
        return {"statusCode": 502, "body": json.dumps({"error": str(e)})}

    answer = response["output"]["message"]["content"][0]["text"]
    input_tokens = response["usage"]["inputTokens"]
    output_tokens = response["usage"]["outputTokens"]
    latency_ms = int((time.time() - start_time) * 1000)

    estimated_cost = (
        input_tokens / 1000 * COST_PER_1K_INPUT_TOKENS
        + output_tokens / 1000 * COST_PER_1K_OUTPUT_TOKENS
    )

    try:
        dynamodb.put_item(
            TableName=REQUEST_LOG_TABLE,
            Item={
                "requestId": {"S": str(uuid.uuid4())},
                "timestamp": {"N": str(int(time.time()))},
                "apiKey": {"S": api_key},
                "modelId": {"S": model_id},
                "inputTokens": {"N": str(input_tokens)},
                "outputTokens": {"N": str(output_tokens)},
                "latencyMs": {"N": str(latency_ms)},
                "estimatedCostUsd": {"S": f"{estimated_cost:.6f}"},
            },
        )
    except Exception as e:
        # Logging failures should never block the actual response - the
        # request itself succeeded, only the bookkeeping failed.
        print(f"Request logging failed (non-fatal): {e}", flush=True)

    return {"statusCode": 200, "body": json.dumps({"answer": answer})}