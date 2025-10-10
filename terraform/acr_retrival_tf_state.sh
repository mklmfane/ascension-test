set -euo pipefail

TF_OUT="${TF_OUT:-tf-output-dev.json}"

# ---- helpers ----
is_json () {
  # returns 0 if file begins with '{' after trimming whitespace
  awk 'BEGIN{RS="";} {gsub(/^[[:space:]]+/, "", $0); print substr($0,1,1)}' "$1" 2>/dev/null | grep -qx '{'
}

read_json_key () {
  local file="$1" key="$2"
  python3 - "$file" "$key" <<'PY'
import json, sys
p, k = sys.argv[1], sys.argv[2]
with open(p, 'r', encoding='utf-8') as f:
    d = json.load(f)
print(d.get(k, {}).get('value', ''))
PY
}

fail () { echo "ERROR: $*" >&2; exit 1; }

[ -e "$TF_OUT" ] || fail "TF_OUT does not exist: $TF_OUT"
[ -s "$TF_OUT" ] || fail "TF_OUT exists but is empty: $TF_OUT"

if ! is_json "$TF_OUT"; then
  echo "ERROR: TF_OUT is not JSON. First 120 bytes:"
  head -c 120 "$TF_OUT" | sed -e 's/[^[:print:]\t]/./g'
  echo
  fail "You captured Terraform logs instead of 'terraform output -json'."
fi

# ---- read from JSON outputs (preferred path) ----
RG="$(read_json_key "$TF_OUT" resource_group_name)"
ACR_LOGIN_SERVER="$(read_json_key "$TF_OUT" acr_login_server)"
ACR_NAME_FROM_OUT="$(read_json_key "$TF_OUT" acr_name)"

[ -n "$RG" ] || fail "resource_group_name missing in JSON outputs"

# ---- resolve ACR login server ----
if [ -z "${ACR_LOGIN_SERVER:-}" ]; then
  if [ -n "${ACR_NAME_FROM_OUT:-}" ]; then
    ACR_LOGIN_SERVER="$(az acr show -g "$RG" -n "$ACR_NAME_FROM_OUT" --query loginServer -o tsv)"
  else
    # discover first ACR in the RG
    mapfile -t L < <(az acr list -g "$RG" --query "[].loginServer" -o tsv)
    [ "${#L[@]}" -gt 0 ] || fail "No ACR found in RG '$RG' and no ACR outputs provided."
    ACR_LOGIN_SERVER="${L[0]}"
  fi
fi

[ -n "$ACR_LOGIN_SERVER" ] || fail "Could not resolve ACR login server"
ACR_NAME="${ACR_LOGIN_SERVER%%.*}"
echo "Using ACR: $ACR_NAME ($ACR_LOGIN_SERVER)"
