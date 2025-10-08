# ---------- ACR (sanitized, length-safe) ----------
# ACR name rules: 5-50 chars, lowercase letters/digits only, must start with a letter.

# Suffix length you want to reserve for uniqueness
locals {
  acr_suffix_len = 7

  # Raw prefix you conceptually want (contains dashes now)
  acr_prefix_raw = "ascension-${var.environment}-acr"

  # Keep only [a-z0-9], lowercase it
  acr_prefix_sanitized = lower(replace(local.acr_prefix_raw, "/[^a-z0-9]/", ""))

  # Leave room for suffix to ensure total length <= 50
  acr_prefix_final = substr(local.acr_prefix_sanitized, 0, 50 - local.acr_suffix_len)
}

resource "random_string" "acr_suffix" {
  length  = local.acr_suffix_len
  upper   = false
  special = false
}

# Final ACR name: <prefix><suffix>, e.g. ascensiondevacrabc1234
locals {
  acr_name = "${local.acr_prefix_final}${random_string.acr_suffix.result}"
}

resource "azurerm_container_registry" "acr" {
  name                = local.acr_name
  resource_group_name = var.resource_group_name
  location            = var.rg_location
  sku                 = "Basic"
  admin_enabled       = false
  tags                = var.tags
}
