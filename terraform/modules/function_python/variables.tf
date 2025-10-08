variable "environment" {
  description = "Environment (dev/test/prod)"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Target resource group"
  type        = string
}

variable "vnet_integration_subnet_id" {
  description = "Subnet ID for VNet Integration (delegated to Microsoft.Web/serverFarms)"
  type        = string
}

variable "application_insights_conn_str" {
  description = "App Insights connection string"
  type        = string
}

variable "func_plan_sku" {
  description = "SKU for the Functions App Service Plan"
  type        = string
}


variable "key_vault_id" {
  description = "Key Vault ID for secret references"
  type        = string
}

# NEW: allow reusing an existing App Service Plan instead of creating a second one
variable "service_plan_id" {
  description = "Existing App Service Plan ID to host the Function App. If set, the module will NOT create its own plan."
  type        = string
  default     = ""
}

# NEW: explicit switch instead of inferring from service_plan_id
variable "create_new_plan" {
  description = "If true, the module creates its own App Service Plan; if false, you must pass service_plan_id."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
