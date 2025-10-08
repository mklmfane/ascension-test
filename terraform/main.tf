locals {
  environment         = var.workflow
  resource_group_name = "ascension-up-${local.environment}-rg"

  # Use your existing base name variable if you have it (var.vnet_name = "vnetone" by default)
  vnet_name           = "ascension-up-${local.environment}-vnet"

  # Pick the environment's dedicated CIDR
  vnet_address_space       = var.address_space_by_env[local.environment]

  #Subnet integration CIDR
  subnet_integ_cidr   = var.subnet_integration_cidr_by_env[local.environment]

  tags = merge(var.tags,
    { 
        environment = local.environment 
    })
}

resource "azurerm_resource_group" "ascension_test_rg" {
  name     = local.resource_group_name

  location = var.location
  tags     = local.tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = local.vnet_name
  location            = azurerm_resource_group.ascension_test_rg.location
  resource_group_name = azurerm_resource_group.ascension_test_rg.name
  address_space       = local.vnet_address_space
  tags                = local.tags
}
