#!/usr/bin/env bash
set -euo pipefail

# ========= CONFIG =========
# REQUIRED: Application (client) ID of your ADO service connection (App registration)
SC_CLIENT_ID="331a5bcb-b95d-4529-a528-c858e28d9a89"

# OPTIONAL: pick which enabled subscription index (0-based). Default = 1 (the "second").
SUB_INDEX="${SUB_INDEX:-1}"

# OPTIONAL: force a specific subscription by ID or name via env var
SUB_ID_OVERRIDE="${SUB_ID:-}"
SUB_NAME_OVERRIDE="${SUB_NAME:-}"

# Also grant Contributor/User Access Administrator so TF can create KVs & role assignments
GRANT_CONTRIBUTOR=true
GRANT_UAA=true

# ========= LOGIN =========
az account show >/dev/null 2>&1 || az login --only-show-errors >/dev/null

# ========= SELECT SUBSCRIPTION =========
choose_subscription() {
  # If user provided a specific subscription, use it
  if [[ -n "$SUB_ID_OVERRIDE" ]]; then
    echo "$SUB_ID_OVERRIDE"
    return
  fi
  if [[ -n "$SUB_NAME_OVERRIDE" ]]; then
    az account list --query "[?name=='${SUB_NAME_OVERRIDE}'].id | [0]" -o tsv --only-show-errors
    return
  fi

  # Otherwise pick the Nth enabled subscription (default: second, index=1)
  mapfile -t SUBS < <(az account list --query "[?state=='Enabled'].id" -o tsv --only-show-errors)

  local count="${#SUBS[@]}"
  if (( count == 0 )); then
    echo "ERROR: No enabled subscriptions visible to the current login." >&2
    az account list --query "[].{name:name,id:id,state:state}" -o table --only-show-errors >&2 || true
    exit 1
  fi

  if (( SUB_INDEX < count )); then
    echo "${SUBS[$SUB_INDEX]}"
  else
    # Fallback: pick the last enabled subscription and warn
    echo "WARN: Requested SUB_INDEX=$SUB_INDEX but only $count enabled subscription(s) found; using the last one." >&2
    echo "${SUBS[$((count-1))]}"
  fi
}

TARGET_SUB_ID="$(choose_subscription)"
if [[ -z "$TARGET_SUB_ID" ]]; then
  echo "ERROR: Could not resolve a target subscription." >&2
  az account list --query "[].{name:name,id:id,state:state}" -o table --only-show-errors >&2 || true
  exit 1
fi

echo "Target subscription: $TARGET_SUB_ID"
az account set -s "$TARGET_SUB_ID"

# ========= RESOLVE/ENSURE SERVICE PRINCIPAL =========
# Get the objectId for the SP behind your client ID (create if not present in tenant)
SP_OBJECT_ID="$(az ad sp show --id "$SC_CLIENT_ID" --query id -o tsv --only-show-errors 2>/dev/null || true)"
if [[ -z "$SP_OBJECT_ID" ]]; then
  echo "Service principal for clientId $SC_CLIENT_ID not found in this tenant; creating..."
  az ad sp create --id "$SC_CLIENT_ID" --only-show-errors >/dev/null
  SP_OBJECT_ID="$(az ad sp show --id "$SC_CLIENT_ID" --query id -o tsv --only-show-errors)"
fi
echo "Service principal objectId: $SP_OBJECT_ID"

# ========= ROLE ASSIGNMENTS =========
assign_if_missing () {
  local role="$1" scope="$2"
  # Check if an assignment already exists
  local existing
  existing="$(az role assignment list \
    --assignee-object-id "$SP_OBJECT_ID" \
    --role "$role" \
    --scope "$scope" \
    --query "[0].id" -o tsv --only-show-errors)"
  if [[ -z "$existing" ]]; then
    echo "Granting '$role' at scope: $scope"
    az role assignment create \
      --assignee-object-id "$SP_OBJECT_ID" \
      --assignee-principal-type ServicePrincipal \
      --role "$role" \
      --scope "$scope" \
      --only-show-errors >/dev/null
  else
    echo "Already has '$role' at $scope"
  fi
}

SCOPE="/subscriptions/${TARGET_SUB_ID}"
echo "== Applying at scope: $SCOPE =="

# Data-plane role for all Key Vaults in this subscription (RBAC-mode KVs)
assign_if_missing "Key Vault Administrator" "$SCOPE"

# ARM-plane roles so Terraform can create KVs & assign RBAC
if $GRANT_CONTRIBUTOR; then assign_if_missing "Contributor" "$SCOPE"; fi
if $GRANT_UAA;         then assign_if_missing "User Access Administrator" "$SCOPE"; fi

echo "Done. RBAC may take ~1–2 minutes to propagate."
