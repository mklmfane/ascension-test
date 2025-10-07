
resource "azurerm_resource_group" "ascension_test_rg" {
  name     = "ascesion-test-rg"
  location = "West Europe"
}


resource "azurerm_virtual_network" "azure_vnet_one" {
  name                = "vnetone-start"
  resource_group_name = azurerm_resource_group.ascension_test_rg.name
  location            = azurerm_resource_group.ascension_test_rg.location
  address_space       = ["10.0.0.0/16"]
}