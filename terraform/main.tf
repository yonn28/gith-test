# -----------------------------------------------------------------------------
# rdicidr — static React app on Azure Blob Storage behind Azure CDN,
# with access logs routed to a Log Analytics Workspace.
#
# One isolated environment (devel / stage) per var.environment.
# Usage:
#   terraform init
#   terraform plan  -var-file=environments/devel.tfvars
#   terraform apply -var-file=environments/devel.tfvars
# -----------------------------------------------------------------------------

locals {
  name_suffix = "${var.project}-${var.environment}"

  common_tags = merge({
    project     = var.project
    environment = var.environment
    managed_by  = "terraform"
  }, var.tags)
}

# Random suffix so globally-unique names (storage / CDN endpoint) don't collide
resource "random_string" "suffix" {
  length  = 4
  lower   = true
  upper   = false
  numeric = true
  special = false
}

# --------------------------- Resource Group ---------------------------------

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.name_suffix}"
  location = var.location
  tags     = local.common_tags
}

# --------------------------- Storage (static site) --------------------------

resource "azurerm_storage_account" "this" {
  # 3-24 chars, lowercase alphanumeric, globally unique
  name                     = "st${var.project}${var.environment}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false

  tags = local.common_tags
}

resource "azurerm_storage_account_static_website" "this" {
  storage_account_id = azurerm_storage_account.this.id
  index_document     = "index.html"
  # SPA fallback: unknown routes are served by the app itself
  error_404_document = "index.html"
}

# --------------------------- Azure CDN (Front Door Standard) ----------------
# Classic "Azure CDN from Microsoft" no longer allows new profile creation;
# Azure Front Door Standard is its successor.

resource "azurerm_cdn_frontdoor_profile" "this" {
  name                = "afd-${local.name_suffix}"
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "Standard_AzureFrontDoor"
  tags                = local.common_tags
}

resource "azurerm_cdn_frontdoor_endpoint" "this" {
  name                     = "fde-${local.name_suffix}-${random_string.suffix.result}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  tags                     = local.common_tags
}

resource "azurerm_cdn_frontdoor_origin_group" "this" {
  name                     = "og-staticwebsite"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  session_affinity_enabled = false

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }
}

resource "azurerm_cdn_frontdoor_origin" "this" {
  name                          = "staticwebsite"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this.id

  enabled                        = true
  host_name                      = azurerm_storage_account.this.primary_web_host
  origin_host_header             = azurerm_storage_account.this.primary_web_host
  http_port                      = 80
  https_port                     = 443
  priority                       = 1
  weight                         = 1000
  certificate_name_check_enabled = true

  depends_on = [azurerm_storage_account_static_website.this]
}

# Single route: serve everything from the static website origin,
# redirecting HTTP -> HTTPS for every visitor.
resource "azurerm_cdn_frontdoor_route" "this" {
  name                          = "route-default"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.this.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.this.id]

  supported_protocols    = ["Http", "Https"]
  https_redirect_enabled = true
  forwarding_protocol    = "HttpsOnly"
  patterns_to_match      = ["/*"]
  link_to_default_domain = true
}

# --------------------------- Log Analytics ----------------------------------

resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-${local.name_suffix}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = local.common_tags
}

# Front Door access logs -> Log Analytics (lives at profile level)
resource "azurerm_monitor_diagnostic_setting" "cdn_access_logs" {
  name                       = "diag-cdn-${local.name_suffix}"
  target_resource_id         = azurerm_cdn_frontdoor_profile.this.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log {
    category = "FrontDoorAccessLog"
  }

  metric {
    category = "AllMetrics"
  }
}

# Storage (blob) access logs -> Log Analytics
resource "azurerm_monitor_diagnostic_setting" "storage_blob_logs" {
  name                       = "diag-blob-${local.name_suffix}"
  target_resource_id         = "${azurerm_storage_account.this.id}/blobServices/default"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  metric {
    category = "Transaction"
  }
}
