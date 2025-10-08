resource "random_string" "kv_suffix" {
  length  = 4
  upper   = false
  special = false
}

locals {
  subnet_integ_cidr   = var.subnet_integration_cidr_by_env[local.environment]
  subnet_integ_name   = "snet-${local.environment}-integration"

  appsp_plan_name     = "plan-${local.environment}-web"
  webapp_name         = "web-react-${local.environment}-${random_string.kv_suffix.result}"

  kv_name = "kv-${replace(local.environment, "_", "-")}-ascension-${random_string.kv_suffix.result}"
  ai_name             = "ai-${local.environment}-ascension"
}

data "azurerm_client_config" "current" {}



# ---------------------------
# Networking: VNet + Integration Subnet
# ---------------------------
resource "azurerm_subnet" "integration" {
  name                 = local.subnet_integ_name
  resource_group_name  = azurerm_resource_group.ascension_test_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [local.subnet_integ_cidr]

  # Required for App Service/Function VNet Integration
  delegation {
    name = "webapp-delegation"
    service_delegation {
      name = "Microsoft.Web/serverFarms"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
    }
  }

  # Allow this subnet to use Key Vault over service endpoints (for Key Vault network ACLs)
  service_endpoints = ["Microsoft.KeyVault"]
}

# ---------------------------
# Observability: Application Insights
# ---------------------------
resource "azurerm_application_insights" "ai" {
  name                = local.ai_name
  location            = azurerm_resource_group.ascension_test_rg.location
  resource_group_name = azurerm_resource_group.ascension_test_rg.name
  application_type    = "web"

  tags     = local.tags
}

# ---------------------------
# Key Vault (RBAC + Network ACLs)
# ---------------------------
resource "azurerm_key_vault" "kv" {
  name                        = lower(replace(local.kv_name, "_", "-"))
  location                    = azurerm_resource_group.ascension_test_rg.location
  resource_group_name         = azurerm_resource_group.ascension_test_rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  enable_rbac_authorization   = var.kv_rbac_enabled
  #soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  # NOTE: With default_action = "Deny", only the allowed subnet can reach KV.
  # Terraform (running outside that VNet) can still manage secrets because RBAC is granted,
  # BUT if your agent is *not* on that subnet, you may also need a temporary ip_rules allowlist.
  network_acls {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    virtual_network_subnet_ids = [azurerm_subnet.integration.id]
    # ip_rules = ["<your-agent-public-ip/32>"] # optional bootstrap if needed
  }

  tags     = local.tags
}

# -------- Data-plane RBAC so Terraform can manage secrets --------
# Grant to *current* Terraform caller (your AAD user/SP running 'az login')
data "azurerm_role_definition" "kv_admin" {
  name  = "Key Vault Administrator"
  scope = azurerm_key_vault.kv.id
}

resource "azurerm_role_assignment" "kv_admin_self" {
  scope              = azurerm_key_vault.kv.id
  role_definition_id = data.azurerm_role_definition.kv_admin.id
  principal_id       = data.azurerm_client_config.current.object_id
}

data "azurerm_role_definition" "kv_secrets_officer" {
  name  = "Key Vault Secrets Officer"
  scope = azurerm_key_vault.kv.id
}

resource "azurerm_role_assignment" "kv_secrets_officer_self" {
  scope              = azurerm_key_vault.kv.id
  role_definition_id = data.azurerm_role_definition.kv_secrets_officer.id
  principal_id       = data.azurerm_client_config.current.object_id
}

# (Optional) also grant to your Azure DevOps service connection principal
resource "azurerm_role_assignment" "kv_secrets_officer_pipeline" {
  count             = var.pipeline_principal_id == "" ? 0 : 1
  scope             = azurerm_key_vault.kv.id
  role_definition_id = data.azurerm_role_definition.kv_secrets_officer.id
  principal_id       = var.pipeline_principal_id
}

# Allow time for RBAC propagation before creating secrets
resource "time_sleep" "kv_rbac_delay" {
  create_duration = "90s"
  depends_on = [
    azurerm_role_assignment.kv_admin_self,
    azurerm_role_assignment.kv_secrets_officer_self,
    azurerm_role_assignment.kv_secrets_officer_pipeline
  ]
}

# Example secret to prove KV wiring (now safe)
resource "azurerm_key_vault_secret" "example" {
  count        = var.create_kv_bootstrap_secret ? 1 : 0
  name         = "API-SECRET"
  value        = "replace-me"
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [time_sleep.kv_rbac_delay]
}


# ---------------------------
# Frontend: App Service Plan + Linux Web App (React)
# ---------------------------
resource "azurerm_service_plan" "appsp" {
  name                = local.appsp_plan_name
  location            = azurerm_resource_group.ascension_test_rg.location
  resource_group_name = azurerm_resource_group.ascension_test_rg.name
  os_type             = "Linux"
  sku_name            = var.web_plan_sku

  timeouts { 
    create = "20m" 
  }

  tags     = local.tags
}

resource "azurerm_linux_web_app" "react_web" {
  name                = local.webapp_name
  resource_group_name = azurerm_resource_group.ascension_test_rg.name
  location            = azurerm_resource_group.ascension_test_rg.location
  service_plan_id     = azurerm_service_plan.appsp.id

  identity { type = "SystemAssigned" }

  site_config {
    always_on = true
    application_stack {
      node_version = "18-lts"
    }
   }

  app_settings = merge(
  {
    WEBSITE_RUN_FROM_PACKAGE              = "0"
    APPINSIGHTS_INSTRUMENTATIONKEY        = azurerm_application_insights.ai.instrumentation_key
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.ai.connection_string
  },
  var.create_kv_bootstrap_secret ? {
    # Only valid when count = 1 → use index [0]
    REACT_APP_API_SECRET = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.example[0].id})"
  } : {
    # No secret resource created yet → construct the URI without depending on the resource
    REACT_APP_API_SECRET = "@Microsoft.KeyVault(SecretUri=https://${azurerm_key_vault.kv.name}.vault.azure.net/secrets/API-SECRET)"
  })  

  tags     = local.tags

}

# VNet Integration for the Web App (Swift)
resource "azurerm_app_service_virtual_network_swift_connection" "react_web_integ" {
  app_service_id = azurerm_linux_web_app.react_web.id
  subnet_id      = azurerm_subnet.integration.id
}

# Allow the Web App to read secrets from Key Vault (RBAC)
data "azurerm_role_definition" "kv_secrets_user" {
  name  = "Key Vault Secrets User"
  scope = azurerm_key_vault.kv.id
}

resource "azurerm_role_assignment" "webapp_kv_read" {
  scope              = azurerm_key_vault.kv.id
  role_definition_id = data.azurerm_role_definition.kv_secrets_user.id
  principal_id       = azurerm_linux_web_app.react_web.identity[0].principal_id
}

