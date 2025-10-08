locals {
  base         = "func-${var.environment}-ascension"
  plan_name    = "plan-${var.environment}-func"
  storage_name = lower(replace("safunc${var.environment}", "-", ""))

  tags = merge(var.tags,
    { 
        environment = "${var.environment}"
    })
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_storage_account" "func" {
  name                     = substr("${local.storage_name}${random_string.suffix.result}", 0, 24)
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  tags                     = local.tags
}

resource "azurerm_service_plan" "plan" {
  count               = var.create_new_plan ? 1 : 0

  name                = local.plan_name
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.func_plan_sku 

  tags                = local.tags

  timeouts { 
    create = "20m" 
  }
}


# Choose the plan ID: provided one or the one we created
locals {
  effective_plan_id = var.create_new_plan ? azurerm_service_plan.plan[0].id : var.service_plan_id
}


resource "azurerm_linux_function_app" "fn" {
  name                       = local.base
  
  location                   = var.location
  resource_group_name        = var.resource_group_name
  service_plan_id            = local.effective_plan_id
  storage_account_name       = azurerm_storage_account.func.name
  storage_account_access_key = azurerm_storage_account.func.primary_access_key

  identity { type = "SystemAssigned" }

  site_config {
    application_stack {
      python_version = "3.10"
    }
    always_on = true
  }

  app_settings = {
    FUNCTIONS_EXTENSION_VERSION             = "~4"
    WEBSITE_RUN_FROM_PACKAGE                = "1"
    WEBSITE_ENABLE_SYNC_UPDATE_SITE         = "true"
    APPLICATIONINSIGHTS_CONNECTION_STRING   = var.application_insights_conn_str

    # KV reference (same secret created at root)
    API_SECRET = "@Microsoft.KeyVault(SecretUri=${var.key_vault_id}/secrets/API-SECRET)"
  }

  tags = local.tags
}

resource "azurerm_app_service_virtual_network_swift_connection" "fn_integ" {
  app_service_id = azurerm_linux_function_app.fn.id
  subnet_id      = var.vnet_integration_subnet_id
}

data "azurerm_role_definition" "kv_secrets_user" {
  name  = "Key Vault Secrets User"
  scope = var.key_vault_id
}

resource "azurerm_role_assignment" "fn_kv_read" {
  scope              = var.key_vault_id
  role_definition_id = data.azurerm_role_definition.kv_secrets_user.id
  principal_id       = azurerm_linux_function_app.fn.identity[0].principal_id
}
