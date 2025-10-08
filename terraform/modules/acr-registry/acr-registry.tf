# ---------- ACR ----------
# Name must be globally unique, alphanumeric only (no dashes).


resource "random_string" "acr_suffix" {
  length  = 7
  upper   = false
  special = false
}


locals {
  acr_name = "ascension-${var.environment}-acr-${random_string.acr_suffix.result}"
}

resource "azurerm_container_registry" "acr" {
  name                = local.acr_name

  resource_group_name = var.resource_group_name
  location            = var.rg_location
  sku                 = "Basic"
  admin_enabled       = false
  
  tags                = var.tags
}
