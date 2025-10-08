# ---------------------------
# Azure container registry for frontend images
# ---------------------------

module "azure_registry_container" {
  source              = "./modules/acr-registry"

  environment         = local.environment
  frontend_image_name = var.frontend_image_name
  frontend_image_tag  = var.frontend_image_tag

  resource_group_name = local.resource_group_name
  rg_location         = local.rg_location

  tags                = local.tags
}
