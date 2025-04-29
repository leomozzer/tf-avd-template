data "azurerm_subnet" "snet" {
  name                 = var.avd_vnet_name
  resource_group_name  = var.spoke_resource_group_name
  virtual_network_name = var.spoke_vnet_name
}

# Get the service principal for Azure Vitual Desktop
data "azuread_service_principal" "spn" {
  client_id = "9cdead84-a844-4324-93f2-b2e6bb768d07"
}

data "azurerm_role_definition" "power_role" {
  name = "Desktop Virtualization Power On Off Contributor"
}

# Get an existing built-in role definition
data "azurerm_role_definition" "this" {
  name = "Desktop Virtualization User"
}
