output "resource_group_name" {
  description = "Resource group of the environment."
  value       = azurerm_resource_group.this.name
}

output "storage_account_name" {
  description = "Storage account hosting the static site (target for the build upload)."
  value       = azurerm_storage_account.this.name
}

output "static_website_url" {
  description = "Direct URL of the static website (origin)."
  value       = azurerm_storage_account.this.primary_web_endpoint
}

output "cdn_profile_name" {
  description = "Front Door profile name (used by the CD pipeline for cache purge)."
  value       = azurerm_cdn_frontdoor_profile.this.name
}

output "cdn_endpoint_name" {
  description = "Front Door endpoint name (used by the CD pipeline for cache purge)."
  value       = azurerm_cdn_frontdoor_endpoint.this.name
}

output "cdn_endpoint_url" {
  description = "Public URL of the application behind Azure Front Door."
  value       = "https://${azurerm_cdn_frontdoor_endpoint.this.host_name}"
}

output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace receiving the access logs."
  value       = azurerm_log_analytics_workspace.this.id
}
