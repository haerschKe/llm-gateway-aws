# ---------------------------------------------------------------------------
# Gateway Lambda role (gateway.py)
# ---------------------------------------------------------------------------

# Trust policy: defines WHO may assume the role.
# Here: only the Lambda service itself.
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "gateway_lambda" {
  name               = "llm-gateway-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

# Permission policy: defines WHAT the role may do.
# Deliberately scoped to the two required Bedrock Runtime actions (no "*" action wildcard).
# resources = ["*"] because Bedrock model invocations don't support more granular per-call ARNs.
data "aws_iam_policy_document" "bedrock_invoke" {
  statement {
    actions   = ["bedrock:InvokeModel", "bedrock:Converse"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "bedrock_access" {
  name   = "bedrock-invoke"
  role   = aws_iam_role.gateway_lambda.id
  policy = data.aws_iam_policy_document.bedrock_invoke.json
}

# Phase 4: write access to the request log table
data "aws_iam_policy_document" "request_log_write" {
  statement {
    actions   = ["dynamodb:PutItem"]
    resources = [aws_dynamodb_table.request_log.arn]
  }
}

resource "aws_iam_role_policy" "request_log_access" {
  name   = "dynamodb-request-log"
  role   = aws_iam_role.gateway_lambda.id
  policy = data.aws_iam_policy_document.request_log_write.json
}

# Phase 6: read/write access to the response cache table
data "aws_iam_policy_document" "cache_access" {
  statement {
    actions   = ["dynamodb:GetItem", "dynamodb:PutItem"]
    resources = [aws_dynamodb_table.response_cache.arn]
  }
}

resource "aws_iam_role_policy" "cache_dynamodb_access" {
  name   = "dynamodb-cache"
  role   = aws_iam_role.gateway_lambda.id
  policy = data.aws_iam_policy_document.cache_access.json
}

# ---------------------------------------------------------------------------
# Authorizer Lambda role (authorizer.py) - Phase 3
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "authorizer_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "authorizer_lambda" {
  name               = "llm-gateway-authorizer-role"
  assume_role_policy = data.aws_iam_policy_document.authorizer_assume.json
}

data "aws_iam_policy_document" "authorizer_dynamodb" {
  statement {
    actions   = ["dynamodb:GetItem"]
    resources = [aws_dynamodb_table.api_keys.arn]
  }
  statement {
    actions   = ["dynamodb:UpdateItem"]
    resources = [aws_dynamodb_table.rate_limits.arn]
  }
}

resource "aws_iam_role_policy" "authorizer_dynamodb_access" {
  name   = "dynamodb-access"
  role   = aws_iam_role.authorizer_lambda.id
  policy = data.aws_iam_policy_document.authorizer_dynamodb.json
}