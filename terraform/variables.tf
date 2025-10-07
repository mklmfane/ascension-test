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

variable "location" {
  description = "Azure region"
  type        = string
  default     = "West Europe" # or "westeurope"
}


variable "tags" {
  description = "Additional resource tags"
  type        = map(string)
  default     = {}
}
