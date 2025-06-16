data "azurerm_subnet" "subnet" {
  resource_group_name  = var.virtual_network_resource_group_name
  virtual_network_name = var.virtual_network_name
  name                 = var.subnet_name
}
