variable "workflow" {
  description = "Workflow environment: dev, test, or prod"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "prod"], var.workflow)
    error_message = "Workflow must be one of: dev, test, prod."
  }
}

# NEW: per-environment CIDRs so dev/test/prod don't overlap
variable "address_space_by_env" {
  description = "VNet CIDR per environment."
  type        = map(list(string))
  default = {
    dev  = ["10.10.0.0/16"]
    test = ["10.20.0.0/16"]
    prod = ["10.30.0.0/16"]
  }
}

# If true -> create RG; if false -> use an existing RG with the same name
variable "create_rg" { 
  description = "Validate if resoruce group exists"
  type = bool  
  default = true 
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "North Europe"
}


# --- NEW: VNet Integration subnet CIDR per environment (must be within the VNet range)
variable "subnet_integration_cidr_by_env" {
  description = "Subnet CIDR for App/Function VNet Integration (one per env)."
  type        = map(string)
  default = {
    dev  = "10.10.1.0/24"
    test = "10.20.1.0/24"
    prod = "10.30.1.0/24"
  }
}


variable "web_plan_sku" {
  description = "SKU for Web App Service Plan"
  type        = string
  default     = "S1"  
}

variable "func_plan_sku" {
  description = "SKU for Service Plan of Function App"
  type        = string
  default     = "S1" 
}

# --- NEW: enable RBAC mode for Key Vault (recommended)
variable "kv_rbac_enabled" {
  description = "Enable RBAC authorization on Key Vault."
  type        = bool
  default     = true
}

variable "create_kv_bootstrap_secret" {
  description = "If true, creates a test secret in Key Vault after RBAC propagation."
  type        = bool
  default     = false
}


variable "pipeline_principal_id" {
  description = "If true, creates a principle_id will be created."
  type        = string
  default     = "4caad26c-42ac-4643-867a-6fb323d62e4a"
}

variable "tags" {
  description = "Additional resource tags"
  type        = map(string)
  default     = {}
}
