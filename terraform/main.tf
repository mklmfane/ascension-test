locals {
  environment         = var.workflow
  resource_group_name = "ascension-up-${local.environment}-rg"

  # pick the *object* once, using conditional (only one branch is evaluated)
  rg_obj      = var.create_rg ? azurerm_resource_group.ascension_test_rg[0] : data.azurerm_resource_group.existing[0]
  rg_name     = local.rg_obj.name
  rg_location = local.rg_obj.location

  vnet_name          = "ascension-up-${local.environment}-vnet"
  vnet_address_space = var.address_space_by_env[local.environment]

  tags = merge(var.tags, { 
    environment = local.environment 
  })
}

# Lookup only when NOT creating the resource group
data "azurerm_resource_group" "existing" {
  count = var.create_rg ? 0 : 1
  name  = local.resource_group_name
}

# Create only when requested
resource "azurerm_resource_group" "ascension_test_rg" {
  count    = var.create_rg ? 1 : 0
  name     = local.resource_group_name
  location = var.location
  tags     = local.tags
}

# Create a VNet for App Service + Function integration
resource "azurerm_virtual_network" "vnet" {
  name                = local.vnet_name
  location            = azurerm_resource_group.ascension_test_rg[0].location
  resource_group_name = azurerm_resource_group.ascension_test_rg[0].name
  address_space       = local.vnet_address_space
  tags                = local.tags
}
