# --------------------------- Azure credentials ------------------------------
# Values come from secrets.auto.tfvars (gitignored) or ARM_* env vars.

variable "client_id" {
  type        = string
  description = "Service Principal client ID."
  sensitive   = true
}

variable "client_secret" {
  type        = string
  description = "Service Principal client secret."
  sensitive   = true
}

variable "tenant_id" {
  type        = string
  description = "Azure AD tenant ID."
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID."
}

# --------------------------- Project settings -------------------------------

variable "project" {
  type        = string
  description = "Short project name used as prefix for every resource."
  default     = "rdicidr"
}

variable "environment" {
  type        = string
  description = "Target environment to provision (devel or stage)."

  validation {
    condition     = contains(["devel", "stage"], var.environment)
    error_message = "environment must be one of: devel, stage."
  }
}

variable "location" {
  type        = string
  description = "Azure region for all resources."
  default     = "eastus2"
}

variable "log_retention_days" {
  type        = number
  description = "Retention (days) for the Log Analytics Workspace."
  default     = 30
}

variable "tags" {
  type        = map(string)
  description = "Extra tags applied to every resource."
  default     = {}
}
