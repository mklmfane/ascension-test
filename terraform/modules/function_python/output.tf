output "default_hostname" {
  value = azurerm_linux_function_app.fn.default_hostname
}

output "azure_function_name" {
  value = azurerm_linux_function_app.fn.name
}
