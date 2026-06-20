# ============================================================
# Terraform Sample — Zenith Readable Theme Test
# ============================================================

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstate"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
}

# ------------------------------------------------------------
# Variables
# ------------------------------------------------------------

variable "environment" {
  description = "Deployment environment (dev, test, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Environment must be dev, test, or prod."
  }
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "australiaeast"
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

variable "app_settings" {
  description = "App Service application settings"
  type = map(object({
    value       = string
    is_secret   = optional(bool, false)
  }))
  default = {}
}

# ------------------------------------------------------------
# Locals
# ------------------------------------------------------------

locals {
  prefix = "zenith-${var.environment}"
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "Terraform"
    CreatedAt   = timestamp()
  })
  max_workers = var.environment == "prod" ? 10 : 2
}

# ------------------------------------------------------------
# Data Sources
# ------------------------------------------------------------

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "main" {
  name = "rg-${local.prefix}"
}

# ------------------------------------------------------------
# Resources
# ------------------------------------------------------------

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_storage_account" "app" {
  name                     = "st${replace(local.prefix, "-", "")}${random_string.suffix.result}"
  resource_group_name      = data.azurerm_resource_group.main.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "ZRS"
  min_tls_version          = "TLS1_2"
  https_traffic_only_enabled = true

  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 30
    }
  }

  tags = local.common_tags
}

resource "azurerm_service_plan" "app" {
  name                = "asp-${local.prefix}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.environment == "prod" ? "P2v3" : "B1"
  tags                = local.common_tags
}

resource "azurerm_linux_web_app" "app" {
  name                = "app-${local.prefix}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  service_plan_id     = azurerm_service_plan.app.id

  site_config {
    always_on        = var.environment == "prod"
    http2_enabled    = true
    health_check_path = "/health"

    application_stack {
      node_version = "20-lts"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  dynamic "app_settings" {
    for_each = var.app_settings
    content {
      name  = app_settings.key
      value = app_settings.value.value
    }
  }

  tags = local.common_tags
}

# ------------------------------------------------------------
# Outputs
# ------------------------------------------------------------

output "app_url" {
  description = "The default hostname of the web app"
  value       = "https://${azurerm_linux_web_app.app.default_hostname}"
}

output "storage_connection_string" {
  description = "Storage account primary connection string"
  value       = azurerm_storage_account.app.primary_connection_string
  sensitive   = true
}

output "principal_id" {
  description = "Managed identity principal ID"
  value       = azurerm_linux_web_app.app.identity[0].principal_id
}
