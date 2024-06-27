data "azurerm_client_config" "current" {}

data "azurerm_virtual_network" "vnet_hub" {
  name                = var.data_vnet_hub.name
  resource_group_name = var.data_vnet_hub.resource_group_name
}
