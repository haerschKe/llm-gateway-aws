terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.20.0" # python lambda 3.14 runtime requires AWS provider >= 6.20.0
    }
  }
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    apigatewayv2   = "http://localhost:4566"
    bedrock        = "http://localhost:4566" # Control-Plane; exists in Provider, actually not used here
    dynamodb       = "http://localhost:4566"
    iam            = "http://localhost:4566"
    lambda         = "http://localhost:4566"
    logs           = "http://localhost:4566"
    secretsmanager = "http://localhost:4566"
  }
}