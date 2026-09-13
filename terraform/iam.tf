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