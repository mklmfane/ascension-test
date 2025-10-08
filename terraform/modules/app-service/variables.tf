variable "environment" {
  description = "Environment (dev/test/prod)"
  type        = string
}


variable "resource_group_name" {
  description = "Target resource group"
  type        = string
}

variable "resource_group_location" {
  description = "Location of the resource group"
  type        = string
}

variable "pipeline_principal_id" {
  description = "Id of pipeline principal to assign role"
  type        = string
}

variable "vnet_virtual_network_name" {
  description = "VNet ID for VNet Integration"
  type        = string
}


variable "web_plan_sku" {
  description = "SKU for Web App plan"
  type        = string
}

variable "kv_rbac_enabled" { 
    type = bool   
    default = true 
}

variable "create_kv_bootstrap_secret" { 
    type = bool
    default = true 
}

variable "subnet_integration_cidr" {
  description = "CIDR for the integration subnet (must be within the VNet range)."
  type        = string
  default     = ""
}

#variable "vnet_address_space" {
#  description = "VNet address space (list of CIDRs)."
#  type        = list(string)
#}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
