#!/usr/bin/env bash
set -euo pipefail

# get-service-connection.sh
# Fetch metadata for an Azure DevOps service connection by NAME.
# Prereqs:
#   - Azure CLI (az)
#   - DevOps extension: az extension add --name azure-devops
# Auth:
#   - Use a PAT with at least 'Read' on Service Connections.
#   - Either run:      echo "$AZDO_PAT" | az devops login --organization "$ORG_URL"
#     or export env:   AZURE_DEVOPS_EXT_PAT="$AZDO_PAT"

usage() {
  echo "Usage: $0 -o ORG_URL -p PROJECT -n SERVICE_CONNECTION_NAME"
  echo "Example:"
  echo "  $0 -o https://dev.azure.com/myorg -p MyProject -n 'My ARM SC'"
  exit 1
}

ORG_URL="https://dev.azure.com/whatever/"
PROJECT="test-whatever"
SC_NAME="MyServicenameconnection"

while getopts ":o:p:n:" opt; do
  case $opt in
    o) ORG_URL="$OPTARG" ;;
    p) PROJECT="$OPTARG" ;;
    n) SC_NAME="$OPTARG" ;;
    *) usage ;;
  esac
done

if [[ -z "$ORG_URL" || -z "$PROJECT" || -z "$SC_NAME" ]]; then
  usage
fi

# Ensure the devops extension is present (no-op if already installed)
az extension add --name azure-devops >/dev/null 2>&1 || true

# Optional: login with PAT from env var AZDO_PAT if not using AZURE_DEVOPS_EXT_PAT
if [[ -n "${AZDO_PAT:-}" ]]; then
  # Login is idempotent; safe to re-run
  echo "$AZDO_PAT" | az devops login --organization "$ORG_URL" >/dev/null
fi

# Find the service connection by name
SC_JSON=$(az devops service-endpoint list \
  --organization "$ORG_URL" \
  --project "$PROJECT" \
  --query "[?name=='$SC_NAME'] | [0]" -o json)

if [[ "$SC_JSON" == "null" || -z "$SC_JSON" ]]; then
  echo "ERROR: Service connection named '$SC_NAME' not found in project '$PROJECT'."
  exit 2
fi

# Pretty print the full JSON
echo "=== Full service connection JSON ==="
echo "$SC_JSON" | jq .

# Extract common fields
SC_ID=$(echo "$SC_JSON" | jq -r '.id')
SC_TYPE=$(echo "$SC_JSON" | jq -r '.type')
SC_URL=$(echo "$SC_JSON" | jq -r '.url')
AUTH_SCHEME=$(echo "$SC_JSON" | jq -r '.authorization.scheme // "N/A"')
SUBSCRIPTION_ID=$(echo "$SC_JSON" | jq -r '.data.subscriptionId // "N/A"')
SPN_ID=$(echo "$SC_JSON" | jq -r '.authorization.parameters.serviceprincipalid // "N/A"')
AZURE_ENV=$(echo "$SC_JSON" | jq -r '.data.environment // "N/A"')
SCOPE=$(echo "$SC_JSON" | jq -r '.data.scope // "N/A"')

echo
echo "=== Key Fields ==="
echo "ID:                 $SC_ID"
echo "Name:               $SC_NAME"
echo "Type:               $SC_TYPE"
echo "URL:                $SC_URL"
echo "Auth Scheme:        $AUTH_SCHEME"
echo "Subscription ID:    $SUBSCRIPTION_ID"
echo "Service Principal:  $SPN_ID"
echo "Azure Environment:  $AZURE_ENV"
echo "Scope:              $SCOPE"
echo
echo "Note: Secrets (e.g., client secret/cert) cannot be retrieved for security reasons."


# After you've set SC_JSON (from az devops service-endpoint list ...)

# Prefer: read clientId directly from the service connection (if present)
APP_CLIENT_ID=$(echo "$SC_JSON" | jq -r '.authorization.parameters.serviceprincipalid // empty')

if [[ -n "$APP_CLIENT_ID" ]]; then
  echo "Application (client) ID (from Service Connection): $APP_CLIENT_ID"
else
  # Fallback: if the ID you printed is the AAD App OBJECT ID, resolve clientId via Graph
  # NOTE: Replace APP_REG_OBJECT_ID with the ID you already have (aa6ed1ea-...).
  APP_REG_OBJECT_ID="$SC_ID"   # <- if your printed ID is the AAD App Object ID
  APP_CLIENT_ID=$(az ad app show --id "$APP_REG_OBJECT_ID" --query appId -o tsv 2>/dev/null || true)
  if [[ -n "$APP_CLIENT_ID" ]]; then
    echo "Application (client) ID (from App Registration lookup): $APP_CLIENT_ID"
  else
    echo "ERROR: Could not resolve Application (client) ID. Ensure the ID is the App Registration OBJECT ID and you ran 'az login'."
    exit 4
  fi
fi
