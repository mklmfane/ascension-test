#!/usr/bin/env bash
set -euo pipefail

# ===== Local “pipeline” variables you can tweak =====
ENV="dev"
DRY_RUN="${DRY_RUN:-1}"              # 1 = skip az/docker; 0 = actually run them
WORKSPACE="$(pwd)/_pw"               # stand-in for $(Pipeline.Workspace)
SOURCES_DIR="$(pwd)"                 # stand-in for $(Build.SourcesDirectory)
BUILD_ID="${BUILD_ID:-12345}"        # stand-in for $(Build.BuildId)

# Make a fake workspace dir and put the TF outputs where the script expects them
mkdir -p "$WORKSPACE/tf-outputs-${ENV}"
TF_OUT="${WORKSPACE}/tf-outputs-${ENV}/tf-outputs.${ENV}.json"
cp -f "./tf-outputs.${ENV}.json" "$TF_OUT"

test -f "$TF_OUT" || { echo "Missing TF outputs at $TF_OUT"; exit 1; }

# ----- Read resource group (no heredocs, no KeyError) -----
RG=$(python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(d.get('resource_group_name',{}).get('value',''))" "$TF_OUT")
test -n "$RG" || { echo "resource_group_name missing in TF outputs"; exit 1; }
echo "RG=$RG"

# ----- Resolve ACR login server (direct -> name -> discover) -----
ACR_LOGIN_SERVER=$(python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(d.get('acr_login_server',{}).get('value',''))" "$TF_OUT")

if [ -z "$ACR_LOGIN_SERVER" ]; then
  ACR_NAME_FROM_OUT=$(python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(d.get('acr_name',{}).get('value',''))" "$TF_OUT")
  if [ -n "$ACR_NAME_FROM_OUT" ]; then
    if [ "$DRY_RUN" = "1" ]; then
      echo "[DRY_RUN] az acr show -g '$RG' -n '$ACR_NAME_FROM_OUT' --query loginServer -o tsv"
      ACR_LOGIN_SERVER="${ACR_NAME_FROM_OUT}.azurecr.io"
    else
      ACR_LOGIN_SERVER=$(az acr show -g "$RG" -n "$ACR_NAME_FROM_OUT" --query loginServer -o tsv)
    fi
  else
    if [ "$DRY_RUN" = "1" ]; then
      echo "[DRY_RUN] az acr list -g '$RG' --query '[].loginServer' -o tsv"
      # Pretend one ACR exists in the RG:
      ACR_LOGIN_SERVER="ascensiondevacrcaxbsaw.azurecr.io"
    else
      mapfile -t L < <(az acr list -g "$RG" --query "[].loginServer" -o tsv)
      if [ "${#L[@]}" -eq 0 ]; then
        echo "No ACR found in RG '$RG' and no outputs provided."; exit 1
      fi
      ACR_LOGIN_SERVER="${L[0]}"
    fi
  fi
fi

test -n "$ACR_LOGIN_SERVER" || { echo "Could not resolve ACR login server"; exit 1; }
ACR_NAME="${ACR_LOGIN_SERVER%%.*}"
echo "Using ACR: $ACR_NAME ($ACR_LOGIN_SERVER)"

# ----- Check Docker & az as needed -----
if [ "$DRY_RUN" != "1" ]; then
  if ! command -v docker >/dev/null 2>&1; then
    echo "Docker not found on this machine."; exit 1
  fi
  az acr login -n "$ACR_NAME"
else
  echo "[DRY_RUN] Skipping Docker/Azure steps"
fi

# ----- Frontend layout checks -----
FRONTEND_DIR="${SOURCES_DIR}/frontend"
test -f "$FRONTEND_DIR/Dockerfile" || { echo "frontend/Dockerfile not found at ${FRONTEND_DIR}/Dockerfile"; exit 1; }
test -f "$FRONTEND_DIR/nginx.conf" || { echo "frontend/nginx.conf not found at ${FRONTEND_DIR}/nginx.conf"; exit 1; }

IMG_NAME="frontend-${ENV}"
IMG_TAG="${BUILD_ID}"
IMAGE_URI="${ACR_LOGIN_SERVER}/${IMG_NAME}:${IMG_TAG}"

echo "Will build: ${IMAGE_URI}"

if [ "$DRY_RUN" != "1" ]; then
  docker build -t "$IMAGE_URI" "$FRONTEND_DIR"
  docker push "$IMAGE_URI"
else
  echo "[DRY_RUN] docker build -t '$IMAGE_URI' '$FRONTEND_DIR'"
  echo "[DRY_RUN] docker push  '$IMAGE_URI'"
fi

# ----- Write the image.json metadata like the pipeline does -----
META_DIR="${WORKSPACE}/frontend-image"
mkdir -p "$META_DIR"
cat > "${META_DIR}/image.json" <<EOF
{
  "acr_login_server": "$ACR_LOGIN_SERVER",
  "image_name": "$IMG_NAME",
  "image_tag": "$IMG_TAG",
  "image_uri": "$IMAGE_URI"
}
EOF

echo "Wrote ${META_DIR}/image.json"
