output "react_web_default_hostname" { 
    value = azurerm_linux_web_app.react_web.default_hostname 
}
output "function_default_hostname"  { 
    value = module.function_python.default_hostname 
}

output "key_vault_name" { 
    value = azurerm_key_vault.kv.name 
}
