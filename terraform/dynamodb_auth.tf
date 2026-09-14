resource "aws_dynamodb_table" "api_keys" {
  name         = var.api_keys_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "apiKey"

  attribute {
    name = "apiKey"
    type = "S"
  }
}

# Separate table for the request counter (rate limiting). TTL ensures old
# counters expire automatically instead of letting the table grow unbounded.
resource "aws_dynamodb_table" "rate_limits" {
  name         = var.rate_limits_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "apiKeyWindow"

  attribute {
    name = "apiKeyWindow"
    type = "S"
  }

  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }
}