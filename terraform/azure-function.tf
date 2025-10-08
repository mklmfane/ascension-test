# ---------------------------
# Backend: Python FastAPI Azure Function (MODULE)
# ---------------------------

module "function_python" {
  source                        = "./modules/function_python"

  environment                   = local.environment
  location                      = local.rg_location
  resource_group_name           = local.rg_name

  # Reuse plan & networking from app_service module (this is the dependency!)
  create_new_plan               = false
  service_plan_id               = module.app_service.service_plan_id
  vnet_integration_subnet_id    = module.app_service.integration_subnet_id

  application_insights_conn_str = module.app_service.app_insights_connection_string
  key_vault_id                  = module.app_service.key_vault_id
  func_plan_sku                 = var.func_plan_sku
  
  tags                          = local.tags

  depends_on = [module.app_service]
}
