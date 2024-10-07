data "azurerm_subnet" "snet" {
  name                 = var.avd_vnet_name
  resource_group_name  = var.spoke_resource_group_name
  virtual_network_name = var.spoke_vnet_name
}
