# -----------------------------------------------------------------------------
# Provider configuration
#
# Authentication is done via environment variables (NEVER hardcode secrets):
#   export ARM_CLIENT_ID="<service-principal-client-id>"
#   export ARM_CLIENT_SECRET="<service-principal-client-secret>"
#   export ARM_TENANT_ID="<azure-ad-tenant-id>"
#   export ARM_SUBSCRIPTION_ID="<azure-subscription-id>"
#
# In GitHub Actions these come from repository/environment secrets.
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.117"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Remote state per environment. Uncomment and create the backend storage
  # account first (or pass -backend-config in the CD pipeline):
  #
  # backend "azurerm" {
  #   resource_group_name  = "rg-tfstate"
  #   storage_account_name = "strdicidrtfstate"
  #   container_name       = "tfstate"
  #   key                  = "rdicidr.<environment>.tfstate"
  # }
}

provider "azurerm" {
  features {}

  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}
