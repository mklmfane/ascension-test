#!/usr/bin/env bash
set -euo pipefail

# ----- CONFIG -----
RG="${RG:-ascension-up-dev-rg}"
FN="${FN:-func-dev-ascension}"
FUNC_REL_PATH="${FUNC_REL_PATH:-Products/__init__.py}"  # change if you want to peek another file
HTTP_TEST_PATH="${HTTP_TEST_PATH:-/api/products}"       # change to your HTTP trigger route (if any)
RETRIES="${RETRIES:-8}"
SLEEP_SEC="${SLEEP_SEC:-5}"

echo "== Checking Function App state =="
az functionapp show -g "$RG" -n "$FN" --query "{state:state, kind:kind, httpsOnly:httpsOnly}" -o table

echo -e "\n== Worker/runtime =="
az functionapp config appsettings list -g "$RG" -n "$FN" \
  --query "[?name=='FUNCTIONS_WORKER_RUNTIME' || name=='FUNCTIONS_EXTENSION_VERSION']" -o table

# ----- Get Kudu publishing credentials (basic auth) -----
echo -e "\n== Fetching publishing profile (Kudu basic auth) =="
TMPXML="$(mktemp)"
az webapp deployment list-publishing-profiles -g "$RG" -n "$FN" --xml > "$TMPXML"

# prefer MSDeploy profile; fallback to any
USER="$(xmllint --xpath "string(//publishProfile[@publishMethod='MSDeploy']/@userName)" "$TMPXML" 2>/dev/null || true)"
PASS="$(xmllint --xpath "string(//publishProfile[@publishMethod='MSDeploy']/@userPWD)"  "$TMPXML" 2>/dev/null || true)"
if [[ -z "$USER" || -z "$PASS" ]]; then
  USER="$(xmllint --xpath "string(//publishProfile[1]/@userName)" "$TMPXML")"
  PASS="$(xmllint --xpath "string(//publishProfile[1]/@userPWD)"  "$TMPXML")"
fi
rm -f "$TMPXML"

if [[ -z "$USER" || -z "$PASS" ]]; then
  echo "ERROR: Could not obtain Kudu publishing credentials. Check that publishing profile is enabled." >&2
  exit 2
fi

SCM_BASE="https://${FN}.scm.azurewebsites.net"
VFS_DIR_URL="${SCM_BASE}/api/vfs/site/wwwroot/"
VFS_FILE_URL="${SCM_BASE}/api/vfs/site/wwwroot/${FUNC_REL_PATH}"

echo -e "\n== Listing /site/wwwroot via Kudu VFS (with retries) =="
BODY="$(mktemp)"; CODE=""
for i in $(seq 1 "$RETRIES"); do
  CODE="$(curl -sS -u "$USER:$PASS" -H "Accept: application/json" -w '%{http_code}' -o "$BODY" "$VFS_DIR_URL" || true)"
  # Expect 200 with JSON array
  if [[ "$CODE" == "200" ]]; then
    break
  fi
  echo "Attempt $i/$RETRIES: Kudu returned HTTP $CODE. Retrying in ${SLEEP_SEC}s..."
  sleep "$SLEEP_SEC"
done

if [[ "$CODE" != "200" ]]; then
  echo "ERROR: Kudu VFS list failed with HTTP $CODE. Last response body follows (truncated):"
  head -c 400 "$BODY" | sed -e 's/[^[:print:]\t]/./g'
  echo
  rm -f "$BODY"
else
  # Now it's safe to pass to jq
  echo "Top-level names in /site/wwwroot:"
  jq -r '.[].name' < "$BODY"
  rm -f "$BODY"

  echo -e "\n== Fetching a specific file to confirm deployment =="
  BODY="$(mktemp)"; CODE="$(curl -sS -u "$USER:$PASS" -w '%{http_code}' -o "$BODY" "$VFS_FILE_URL" || true)"
  if [[ "$CODE" == "200" ]]; then
    head -n 30 "$BODY"
  else
    echo "Could not fetch ${FUNC_REL_PATH} (HTTP $CODE). Check your function folder/file name."
    head -c 400 "$BODY" | sed -e 's/[^[:print:]\t]/./g'; echo
  fi
  rm -f "$BODY"
fi

echo -e "\n== Listing functions via Azure CLI (control plane) =="
az functionapp function list -g "$RG" -n "$FN" -o table || true

# OPTIONAL: hit your HTTP trigger (best-effort)
if [[ -n "${HTTP_TEST_PATH}" ]]; then
  echo -e "\n== Hitting HTTP trigger (best-effort) =="
  # If you have function-level keys, add ?code=... here.
  curl -i "https://${FN}.azurewebsites.net${HTTP_TEST_PATH}" || true
fi

echo -e "\nDone."
