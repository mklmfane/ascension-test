#!/usr/bin/env bash

set -euo pipefail

RG_NAME_PREFIX="ascension-up"
ENV="dev"
LOCATION="northeurope"
RG_STATE="${RG_NAME_PREFIX}-${ENV}-state-rg"
# fixed, deterministic SA name (<=24 chars, lowercase, alnum)
SA_NAME="$(echo "st${RG_NAME_PREFIX}${ENV}tfstate" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9' | cut -c1-24)"
CONTAINER="tfstate-${ENV}"

TFSTATE_RG="${RG_NAME_PREFIX}-${ENV}-state-rg"
TFSTATE_SA="$(echo "st${RG_NAME_PREFIX}${ENV}tfstate" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9' | cut -c1-24)"
TFSTATE_CONTAINER="container"

echo "Backend target => RG=$RG_STATE SA=$SA_NAME container=$CONTAINER key=terraform.${ENV}.tfstate"

# Ensure RG exists
if ! az group show -n "$RG_STATE" >/dev/null 2>&1; then
  echo "Creating resource group: $RG_STATE"
  az group create -n "$RG_STATE" -l "$LOCATION" 1>/dev/null
else
  echo "Reusing resource group: $RG_STATE"
fi

# Ensure Storage Account exists (deterministic name)
if ! az storage account show -g "$RG_STATE" -n "$SA_NAME" >/dev/null 2>&1; then
  echo "Creating storage account: $SA_NAME"
  az storage account create \
    -g "$RG_STATE" -n "$SA_NAME" -l "$LOCATION" \
    --sku Standard_LRS --kind StorageV2 \
    --min-tls-version TLS1_2 \
    --allow-blob-public-access false \
    --encryption-services blob \
    --tags purpose=tfstate env="$ENV" 1>/dev/null
else
 echo "Reusing storage account: $SA_NAME"
fi

# Ensure container exists
KEY="$(az storage account keys list -g "$RG_STATE" -n "$SA_NAME" --query "[0].value" -o tsv)"
az storage container create \
  --name "$CONTAINER" \
  --account-name "$SA_NAME" \
  --account-key "$KEY" 1>/dev/null

terraform  init -input=false -reconfigure \
 -backend-config="resource_group_name=$(TFSTATE_RG)" \
 -backend-config="storage_account_name=$(TFSTATE_SA)" \
 -backend-config="container_name=$(TFSTATE_CONTAINER)" \
 -backend-config="key=terraform.$(env).tfstate"