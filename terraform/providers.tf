terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.20.0" # python lambda 3.14 runtime requires AWS provider >= 6.20.0
    }
  }
}

provider "aws" {
  region                      = var.aws_region
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  # Note: the Terraform AWS provider has no dedicated endpoint key for Bedrock
  # Runtime (Converse/InvokeModel) - only "bedrock" (control plane) exists.
  # This is fine: Terraform never calls Converse itself. That call happens at
  # runtime inside the Lambda function via boto3.client("bedrock-runtime"),
  # whose endpoint resolution comes from the AWS_ENDPOINT_URL env var that
  # floci sets automatically inside its emulated Lambda containers.
  #
  # For a real AWS deployment, remove this whole `endpoints` block (and the
  # hardcoded test credentials above) rather than trying to make it
  # conditional - keeping local-only config in one clearly-marked block
  # is easier to reason about than a "smart" toggle.
  endpoints {
    apigatewayv2   = var.floci_endpoint
    bedrock        = var.floci_endpoint # control plane only; unused here
    dynamodb       = var.floci_endpoint
    iam            = var.floci_endpoint
    lambda         = var.floci_endpoint
    logs           = var.floci_endpoint
    secretsmanager = var.floci_endpoint
  }
}