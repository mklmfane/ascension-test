RG="ascension-up-dev-rg"
FN="func-dev-ascension"
az functionapp show -g "$RG" -n "$FN" --query "{state:state, kind:kind, httpsOnly:httpsOnly}" -o table

# Runtime settings look right?
az functionapp config appsettings list -g "$RG" -n "$FN" \
  --query "[?name=='FUNCTIONS_WORKER_RUNTIME' || name=='FUNCTIONS_EXTENSION_VERSION']" -o table

# Get Kudu basic auth creds
az webapp deployment list-publishing-profiles -g "$RG" -n "$FN" --xml > pub.xml
USER=$(xmllint --xpath "string(//publishProfile[@publishMethod='MSDeploy']/@userName)" pub.xml)
PASS=$(xmllint --xpath "string(//publishProfile[@publishMethod='MSDeploy']/@userPWD)"  pub.xml)

# List top-level of deployed content
curl -s -u "$USER:$PASS" "https://$FN.scm.azurewebsites.net/api/vfs/site/wwwroot/" | jq '.[].name'

# (optional) View a specific file to confirm your version stamp, etc.
curl -s -u "$USER:$PASS" "https://$FN.scm.azurewebsites.net/api/vfs/site/wwwroot/Products/__init__.py" | head -n 20