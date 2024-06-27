#######################
#    Commom locals    #
#######################

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

#########################
#    Resource naming    #
#########################

locals {
  //FSLogix
  fslogix_sta_name     = "sta${var.customershort_name}fslx01"
  fslogix_rg_name      = "rg-${var.customershort_name}-${local.region_name_standardize[var.principal_location]}-fslogix-avd-01"
  fslogix_storage_name = "${var.customershort_name}-vdpool-${var.environment}"

  //Key Vault
  rg_general_name                       = "rg-${var.customershort_name}-${local.region_name_standardize[var.principal_location]}-avdvmcred-01"
  kv_general_name                       = "kv-${var.customershort_name}-${local.region_name_standardize[var.principal_location]}-avdvmcred-01"
  kv_general_soft_delete_retention_days = 7
  kv_general_purge_protection_enabled   = false
  kv_general_sku_name                   = "standard"
}

#################
#   Vnet AVD    #
#################

locals {
  //Used an existing local available in another repo to create the vnet
  //It uses the principle of "hub-spoke", so in this case, our AVD vnet will be an spoke vnet
  default_vnet_avd = flatten([
    for value, key in var.vnet_avd_definition : [
      for index, spoke in lookup(key, "vnets", []) : {
        subscription_id           = key["subscription_id"]
        location                  = spoke["location"] != "" ? spoke["location"] : var.principal_location
        location_short            = "${local.region_name_standardize["${spoke["location"] != "" ? spoke["location"] : var.principal_location}"]}"
        spoke_name                = "spoke-${index > 9 ? "${index + 1}" : "0${index + 1}"}"
        spoke_resource_group_name = "rg-vnet-${local.region_name_standardize["${spoke["location"] != "" ? spoke["location"] : var.principal_location}"]}-spoke-${key["identifier"]}-${index > 9 ? "${index + 1}" : "0${index + 1}"}"
        spoke_vnet_name           = "vnet-${local.region_name_standardize["${spoke["location"] != "" ? spoke["location"] : var.principal_location}"]}-spoke-${key["identifier"]}-${index > 9 ? "${index + 1}" : "0${index + 1}"}"
        address_prefix            = spoke["address_space"]
        subnets = flatten([
          for entry, subnet in spoke["subnets"] : {
            name         = "snet-${var.vnet_avd_definition[value]["identifier"]}-${entry > 9 ? "${entry + 1}" : "0${entry + 1}"}"
            subnet_range = subnet["address_prefix"]
          }
        ])
      }
    ]
  ])
}
