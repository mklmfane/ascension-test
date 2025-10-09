# ACR
output "acr_login_server" { 
    value = azurerm_container_registry.acr.login_server 
}

output "acr_name" { 
    value = azurerm_container_registry.acr.name 
}

output "acr_login_server" { 
    value = azurerm_container_registry.acr.login_server 
}

output "acr_id" { 
    value = azurerm_container_registry.acr.id 
}

# Image coordinates (so the pipeline can read them)

output "frontend_image_name" { 
    value = var.frontend_image_name 
}

output "frontend_image_tag"  { 
    value = var.frontend_image_tag 
}