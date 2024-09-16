#!/bin/bash

set -o errexit -o nounset -o pipefail

# Authenticate to AWS using Github OIDC
IDENTITY_TOKEN=$(
  curl \
    --fail-with-body \
    --silent \
    --show-error \
    --header "Authorization: Bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" \
    --header "User-Agent: actions/oidc-client" \
    --url-query "audience=sts.amazonaws.com" \
    $ACTIONS_ID_TOKEN_REQUEST_URL \
  | jq -r .value
)

# Use the ID token to authenticate to AWS
AWS_CREDS=$(
  aws sts assume-role-with-web-identity \
    --role-arn $ROLE_ARN \
    --role-session-name GitHubActions \
    --web-identity-token "$IDENTITY_TOKEN" \
    --region $REGION \
)

# Set the AWS credentials as environment variables
export AWS_ACCESS_KEY_ID=$(echo $AWS_CREDS | jq -r .Credentials.AccessKeyId)
export AWS_SECRET_ACCESS_KEY=$(echo $AWS_CREDS | jq -r .Credentials.SecretAccessKey)
export AWS_SESSION_TOKEN=$(echo $AWS_CREDS | jq -r .Credentials.SessionToken)
export AWS_DEFAULT_REGION=$REGION
export AWS_REGION=$REGION

# Fetch STS identity
aws sts get-caller-identity --debug