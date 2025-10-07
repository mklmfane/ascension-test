locals {
  environment          = var.workflow
  resource_group_name  = "ascension-${local.environment}-rg"
  vnet_name            = "${var.vnet_name}-${local.environment}-vnet"
  
  tags = merge(
    var.tags,
    {
      environment = local.environment
    }
  )
}


resource "azurerm_resource_group" "ascension_test_rg" {
  name     = local.resource_group_name
  location = var.location
  tags = local.tags
}

resource "azurerm_virtual_network" "azure_vnet_one" {
  name                = "vnetone-${var.workflow}"
  resource_group_name = azurerm_resource_group.ascension_test_rg.name
  location            = azurerm_resource_group.ascension_test_rg.location
  address_space       = ["10.0.0.0/16"]
  tags = local.tags
}