variable "workflow" {
  description = "Workflow environment: dev, test, or prod"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "prod"], var.workflow)
    error_message = "Workflow must be one of: dev, test, prod."
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
