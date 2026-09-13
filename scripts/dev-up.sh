#!/usr/bin/env bash
set -e

# Ollama-Model check
ollama list | grep -q "qwen2.5:0.5b" || ollama pull qwen2.5:0.5b

# start floci
docker compose up -d

# set Env-Vars for AWS CLI/Terraform
export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

# wait until floci is ready
until curl -sf http://localhost:4566/_localstack/health > /dev/null; do sleep 1; done

echo "floci läuft. Endpoint: $AWS_ENDPOINT_URL"