import os
import time

import boto3

dynamodb = boto3.client("dynamodb")

API_KEYS_TABLE = os.environ.get("API_KEYS_TABLE", "llm-gateway-api-keys")
RATE_LIMITS_TABLE = os.environ.get("RATE_LIMITS_TABLE", "llm-gateway-rate-limits")


def handler(event, context):
    api_key = event.get("headers", {}).get("x-api-key")

    if not api_key:
        return {"isAuthorized": False}

    # 1. Check the key against the API keys table
    key_lookup = dynamodb.get_item(
        TableName=API_KEYS_TABLE,
        Key={"apiKey": {"S": api_key}},
    )
    item = key_lookup.get("Item")
    if not item:
        return {"isAuthorized": False}

    rate_limit = int(item["rateLimitPerMinute"]["N"])

    # 2. Rate limiting: simple fixed-window counter per minute.
    #    Key = "apiKey#currentMinute", value is incremented atomically.
    window = int(time.time() // 60)
    counter_key = f"{api_key}#{window}"

    result = dynamodb.update_item(
        TableName=RATE_LIMITS_TABLE,
        Key={"apiKeyWindow": {"S": counter_key}},
        UpdateExpression="ADD requestCount :inc SET expiresAt = :ttl",
        ExpressionAttributeValues={
            ":inc": {"N": "1"},
            ":ttl": {"N": str(int(time.time()) + 120)},  # 2-minute TTL buffer
        },
        ReturnValues="UPDATED_NEW",
    )
    current_count = int(result["Attributes"]["requestCount"]["N"])

    if current_count > rate_limit:
        return {"isAuthorized": False}

    return {"isAuthorized": True, "context": {"apiKey": api_key}}