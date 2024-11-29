data "azurerm_subnet" "snet" {
  name                 = var.avd_vnet_name
  resource_group_name  = var.spoke_resource_group_name
  virtual_network_name = var.spoke_vnet_name
}

data "azuread_service_principal" "avd_sp" {
  count        = var.enable_scaling_plan == true ? 1 : 0
  display_name = "Windows Virtual Desktop" #Also can be the "Azure Virtual Desktop"
}
