# Optional knobs to pass from CI
variable "frontend_image_name" {
  type    = string
  default = "frontend"
}

variable "frontend_image_tag" {
  type    = string
  default = "" # pipeline will pass a value
}

variable "resource_group_name" {
  type    = string
  default = ""
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "rg_location" {
  type    = string
  default = "northeurope"
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}