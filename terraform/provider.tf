terraform {
    required_version = ">= 1.5.0"
    required_providers {
        azurerm = {
            source  = "hashicorp/azurerm"
            version = "~> 3.100"
        }
    }

    backend "azurerm" {}
}

provider "azurerm" {
    features {
        resource_group {
            prevent_deletion_if_contains_resources = false
        }
        key_vault {
            recover_soft_deleted_key_vaults = true
            purge_soft_delete_on_destroy    = true
        }
    }
}


