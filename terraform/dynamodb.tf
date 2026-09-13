resource "aws_dynamodb_table" "request_log" {
  name         = "llm-gateway-requests"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "requestId"

  attribute {
    name = "requestId"
    type = "S"
  }

  # Optional GSI to efficiently query requests by API key, instead of having
  # to scan the entire table for every evaluation (see Schritt 28).
  # For a portfolio project with low traffic a scan is perfectly fine - the
  # GSI just demonstrates that you've thought about scalability.
  attribute {
    name = "apiKey"
    type = "S"
  }

  global_secondary_index {
    name            = "apiKey-index"
    hash_key        = "apiKey"
    projection_type = "ALL"
  }
}