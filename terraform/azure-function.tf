# ---------------------------
# Backend: Python FastAPI Azure Function (MODULE)
# ---------------------------


module "function_python" {
  source                        = "./modules/function_python"

  environment                   = local.environment
  location                      = azurerm_resource_group.ascension_test_rg.location
  resource_group_name           = azurerm_resource_group.ascension_test_rg.name

  # Reuse existing web plan -> avoids second plan create (no 429 path)
  create_new_plan               = false

  service_plan_id               = azurerm_service_plan.appsp.id

  vnet_integration_subnet_id    = azurerm_subnet.integration.id
  application_insights_conn_str = azurerm_application_insights.ai.connection_string
  key_vault_id                  = azurerm_key_vault.kv.id

  func_plan_sku                 = var.func_plan_sku   # ignored when create_new_plan=false

  tags                          = local.tags
}
