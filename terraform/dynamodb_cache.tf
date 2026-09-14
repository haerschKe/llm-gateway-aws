resource "aws_dynamodb_table" "response_cache" {
  name         = "llm-gateway-cache"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "promptHash"

  attribute {
    name = "promptHash"
    type = "S"
  }

  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }
}