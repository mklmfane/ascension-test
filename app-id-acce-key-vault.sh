# ---- inputs ----
SUB_ID="2651642d-e8bb-4270-8616-ca051b63d71e"
RG="vault-access"
VAULT="vault-access-keys"                      # exact vault name
APP_ID="0ae132b5-2182-4943-b5a4-9ebae65f610b"  # service connection's Application (client) ID

# ---- resolve principal & scope ----
az account set -s "$SUB_ID"
SP_OBJECT_ID="$(az ad sp show --id "$APP_ID" --query id -o tsv)"
if [ -z "$SP_OBJECT_ID" ]; then
  echo "Could not resolve service principal object id for appId $APP_ID" >&2; exit 1
fi
SCOPE="/subscriptions/$SUB_ID/resourceGroups/$RG/providers/Microsoft.KeyVault/vaults/$VAULT"

# (optional) ensure KV is in RBAC mode, not access policies
# az keyvault update -g "$RG" -n "$VAULT" --enable-rbac-authorization true

grant() {
  local role="$1"
  local exist
  exist="$(az role assignment list \
    --assignee-object-id "$SP_OBJECT_ID" \
    --scope "$SCOPE" \
    --role "$role" \
    --query "[0].id" -o tsv)"
  if [ -z "$exist" ]; then
    az role assignment create \
      --assignee-object-id "$SP_OBJECT_ID" \
      --assignee-principal-type ServicePrincipal \
      --role "$role" \
      --scope "$SCOPE"
  else
    echo "Role '$role' already exists on scope $SCOPE"
  fi
}

grant "Key Vault Secrets User"   # needed to Get/List secret values
grant "Key Vault Reader"         # optional: mgmt-plane read


az account set -s "$SUB_ID"


# Required to read secret values
az role assignment create \
  --assignee-object-id "$SP_OBJECT_ID" \
  --assignee-principal-type ServicePrincipal \
  --role "Key Vault Secrets User" \
  --scope "$SCOPE"

# Optional (metadata/portal reads)
az role assignment create \
  --assignee-object-id "$SP_OBJECT_ID" \
  --assignee-principal-type ServicePrincipal \
  --role "Key Vault Reader" \
  --scope "$SCOPE"

# 1) SP object id and vault scope (sanity)
echo "$SP_OBJECT_ID"
echo "$SCOPE"

# 2) Role assignments in effect
az role assignment list \
  --assignee-object-id "$SP_OBJECT_ID" \
  --scope "$SCOPE" \
  --query "[].{role:roleDefinitionName,principalType:principalType,id:id}" -o table

# You should see at least:
# Key Vault Secrets User  ServicePrincipal  /subscriptions/.../providers/Microsoft.Authorization/roleAssignments/...

# 3) Vault uses RBAC (should be true)
az keyvault show -g "$RG" -n "$VAULT" --query "properties.enableRbacAuthorization"