# --- Outputs for other modules ---
output "service_plan_id" {
  value = azurerm_service_plan.appsp.id
}

output "integration_subnet_id" {
  value = azurerm_subnet.integration.id
}

output "app_insights_connection_string" {
  value = azurerm_application_insights.ai.connection_string
}

output "key_vault_id" {
  value = azurerm_key_vault.kv.id
}

output "key_vault_name" {
  value = azurerm_key_vault.kv.name
}

output "web_default_hostname" {
  value = azurerm_linux_web_app.react_web.default_hostname
}

output "react_web_name"  { 
  value = azurerm_linux_web_app.react_web.name 
}