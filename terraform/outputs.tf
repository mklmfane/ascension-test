output "react_web_default_hostname" {
  value = module.app_service.web_default_hostname
}

output "key_vault_name" {
  value = module.app_service.key_vault_name
}

output "function_default_hostname" {
  value = module.function_python.default_hostname
}

output "resource_group_name" { 
  value = azurerm_resource_group.ascension_test_rg[0].name 
}

output "azure_function_name"       { 
  value = module.function_python.azure_function_name
}

