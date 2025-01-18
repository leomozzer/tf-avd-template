locals {
  region_name_standardize = {
    "East US"           = "eus"
    "eastus"            = "eus"
    "east us"           = "eus"
    "West US"           = "wus"
    "North Central US"  = "ncus"
    "South Central US"  = "scus"
    "East US 2"         = "eus2"
    "West US 2"         = "wus2"
    "Central US"        = "cus"
    "West Central US"   = "wcus"
    "Canada East"       = "canadaeast"
    "Canada Central"    = "canadacentral"
    "West Europe"       = "weu"
    "westeurope"        = "weu"
    "west europe"       = "weu"
    "North Europe"      = "neu"
    "northeurope"       = "neu"
    "UK South"          = "uks"
    "UK West"           = "ukw"
    "France Central"    = "francecentral"
    "France South"      = "francesouth"
    "Germany North"     = "germanynorth"
    "Germany West"      = "germanywest"
    "Switzerland North" = "swnorth"
    "Switzerland West"  = "swwest"
    "Norway East"       = "noeast"
    "Norway West"       = "nowest"
    # Add more mappings as needed
  }
}

locals {
  resource_group_name            = var.resource_group_name != "" ? var.resource_group_name : "rg-avd-${var.avd_name}-${local.region_name_standardize[var.location]}-${var.environment_name}-${var.avd_index}"
  hostpool_name                  = var.hostpool_name != "" ? var.hostpool_name : "vdpool-avd-${var.avd_name}-${local.region_name_standardize[var.location]}-${var.environment_name}-${var.avd_index}"
  workspace_name                 = var.workspace_name != "" ? var.workspace_name : "vdws-${var.avd_name}-${local.region_name_standardize[var.location]}-${var.environment_name}-${var.avd_index}"
  desktop_application_group_name = "dag-${var.avd_name}-${local.region_name_standardize[var.location]}-${var.environment_name}-${var.avd_index}"
}
