resource "aws_dynamodb_table" "request_log" {
  name         = var.request_log_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "requestId"

  attribute {
    name = "requestId"
    type = "S"
  }

  # Optional GSI to efficiently query requests by API key, instead of having
  # to scan the entire table for every evaluation. For a portfolio project
  # with low traffic a scan is perfectly fine - the GSI just demonstrates
  # that scalability was considered.
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