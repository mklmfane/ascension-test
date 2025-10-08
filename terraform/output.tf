output "react_web_default_hostname" {
  value = module.app_service.web_default_hostname
}

output "key_vault_name" {
  value = module.app_service.key_vault_name
}

output "function_default_hostname" {
  value = module.function_python.default_hostname
}