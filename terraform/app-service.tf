# ---------- FRONTEND + SHARED (App Service) ----------

module "app_service" {
  source                     = "./modules/app-service"

  environment                = local.environment
  resource_group_location    = azurerm_resource_group.ascension_test_rg.location
  resource_group_name        = azurerm_resource_group.ascension_test_rg.name

  vnet_virtual_network_name  = azurerm_virtual_network.vnet.name
  vnet_address_space         = local.vnet_address_space        
  subnet_integration_cidr    = local.subnet_integ_cidr          

  web_plan_sku               = var.web_plan_sku            
  kv_rbac_enabled            = var.kv_rbac_enabled
  create_kv_bootstrap_secret = var.create_kv_bootstrap_secret
  pipeline_principal_id      = var.pipeline_principal_id

  tags                       = local.tags
}
