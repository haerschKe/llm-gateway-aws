import json
import sys
import base64
import traceback
import boto3

bedrock = boto3.client("bedrock-runtime")
print("AWS_ENDPOINT_URL:", boto3.client("bedrock-runtime").meta.endpoint_url)

def handler(event, context):
    print("HANDLER INVOKED - CODE VERSION 2", flush=True)

    raw_body = event.get("body") or "{}"
    if event.get("isBase64Encoded"):
        raw_body = base64.b64decode(raw_body).decode("utf-8")

    body = json.loads(raw_body)
    prompt = body.get("prompt", "")
    model_id = body.get("modelId", "anthropic.claude-3-haiku-20240307-v1:0")

    if not prompt:
        return {"statusCode": 400, "body": json.dumps({"error": "prompt fehlt"})}

    try:
        response = bedrock.converse(
            modelId=model_id,
            messages=[{"role": "user", "content": [{"text": prompt}]}],
        )
    except Exception:
        print("FULL TRACEBACK:", flush=True)
        traceback.print_exc(file=sys.stdout)
        sys.stdout.flush()
        raise

    answer = response["output"]["message"]["content"][0]["text"]
    return {"statusCode": 200, "body": json.dumps({"answer": answer})}