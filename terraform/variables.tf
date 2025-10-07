variable "workflow" {
  description = "Environment name (dev, test, prod). Used for naming & tags."
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "West Europe" # or "westeurope"
}