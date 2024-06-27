

##########################
# Configure Spoke Vnets  #
##########################
module "avd_vnet" {
  source = "../terraform-modules/azapi/vnet"
  for_each = {
    for index, hub in local.default_vnet_avd : index => hub
  }
  location            = each.value.location
  subscription_id     = each.value.subscription_id
  resource_group_name = each.value.spoke_resource_group_name
  vnet_name           = each.value.spoke_vnet_name
  vnet_address_prefix = each.value.address_prefix
  subnets             = each.value.subnets
}

##################################
# Configure Peering hub <> Spoke #
##################################
//This module is used to peer the new vnet avd spoke with the existing hub
//This is not required if the hub spoke topology isn't been used
# module "peering_hub_avd" {
#   source          = "../terraform-modules/azapi/peering-hub-spoke"
#   count           = length(local.default_vnet_avd)
#   vnet_hub_name   = var.data_vnet_hub.name
#   vnet_hub_id     = data.azurerm_virtual_network.vnet_hub.id
#   vnet_spoke_name = module.avd_vnet[count.index].vnet.name
#   vnet_spoke_id   = module.avd_vnet[count.index].vnet.id
# }
