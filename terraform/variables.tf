variable "aws_region" {
  description = "AWS region to deploy into (and to emulate via floci)."
  type        = string
  default     = "us-east-1"
}

variable "floci_endpoint" {
  description = "Local floci endpoint. Only relevant for local development - remove the endpoints block in providers.tf entirely when deploying against real AWS."
  type        = string
  default     = "http://localhost:4566"
}

variable "lambda_runtime" {
  description = "Python runtime for both Lambda functions."
  type        = string
  default     = "python3.14"
}

variable "gateway_lambda_timeout" {
  description = "Timeout (seconds) for the main gateway Lambda."
  type        = number
  default     = 15
}

variable "authorizer_lambda_timeout" {
  description = "Timeout (seconds) for the authorizer Lambda. Kept short since it's on the hot path of every request."
  type        = number
  default     = 5
}

variable "default_model_id" {
  description = "Bedrock model ID used when a request doesn't specify one."
  type        = string
  default     = "anthropic.claude-3-haiku-20240307-v1:0"
}

variable "request_log_table_name" {
  type    = string
  default = "llm-gateway-requests"
}

variable "api_keys_table_name" {
  type    = string
  default = "llm-gateway-api-keys"
}

variable "rate_limits_table_name" {
  type    = string
  default = "llm-gateway-rate-limits"
}

variable "cache_table_name" {
  type    = string
  default = "llm-gateway-cache"
}

variable "cache_ttl_seconds" {
  description = "How long a cached response stays valid."
  type        = number
  default     = 3600
}

variable "stage_throttling_burst_limit" {
  type    = number
  default = 20
}

variable "stage_throttling_rate_limit" {
  type    = number
  default = 10
}