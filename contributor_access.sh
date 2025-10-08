#!/usr/bin/env bash
set -euo pipefail

# ========= INPUTS =========
# Application (client) ID of your ADO service connection or other app
SC_CLIENT_ID="331a5bcb-b95d-4529-a528-c858e28d9a89"

# Also grant Contributor/User Access Administrator so TF can create KVs & role assignments (recommended)
GRANT_CONTRIBUTOR=true
GRANT_UAA=true

# ========= PREP =========
az account show >/dev/null 2>&1 || az login >/dev/null

# Pick the SECOND enabled subscription (0-based index)
SECOND_SUB_ID=$(az account list --query "[?state=='Enabled'][1].id" -o tsv)
if [[ -z "${SECOND_SUB_ID}" ]]; then
  echo "ERROR: Could not resolve the second enabled subscription." >&2
  echo "Available subscriptions:" >&2
  az account list --query "[].{name:name,id:id,state:state}" -o table >&2
  exit 1
fi
echo "Target subscription: ${SECOND_SUB_ID}"
az account set -s "${SECOND_SUB_ID}"

# Resolve the service principal's objectId from clientId (create SP if missing)
SP_OBJECT_ID=$(az ad sp show --id "$SC_CLIENT_ID" --query id -o tsv 2>/dev/null || true)
if [[ -z "$SP_OBJECT_ID" ]]; then
  echo "Service principal for clientId $SC_CLIENT_ID not found; creating..."
  az ad sp create --id "$SC_CLIENT_ID" >/dev/null
  SP_OBJECT_ID=$(az ad sp show --id "$SC_CLIENT_ID" --query id -o tsv)
fi
echo "Service principal objectId: $SP_OBJECT_ID"

# ========= ROLE ASSIGNMENTS =========
assign_if_missing () {
  local role="$1" scope="$2"
  local existing
  existing=$(az role assignment list \
    --assignee-object-id "$SP_OBJECT_ID" \
    --role "$role" \
    --scope "$scope" \
    --query "[0].id" -o tsv)
  if [[ -z "$existing" ]]; then
    echo "Granting '$role' at scope: $scope"
    az role assignment create \
      --assignee-object-id "$SP_OBJECT_ID" \
      --assignee-principal-type ServicePrincipal \
      --role "$role" \
      --scope "$scope" >/dev/null
  else
    echo "Already has '$role' at $scope"
  fi
}

SCOPE="/subscriptions/${SECOND_SUB_ID}"
echo "== Applying at scope: $SCOPE =="

# Data-plane role for ALL Key Vaults in this subscription (RBAC mode KVs)
assign_if_missing "Key Vault Administrator" "$SCOPE"

# (Recommended) ARM-plane roles so Terraform can create vaults and assign RBAC
if $GRANT_CONTRIBUTOR; then assign_if_missing "Contributor" "$SCOPE"; fi
if $GRANT_UAA;         then assign_if_missing "User Access Administrator" "$SCOPE"; fi

echo "Done. RBAC may take ~1–2 minutes to propagate."
