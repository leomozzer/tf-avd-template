# Get the service principal for Azure Vitual Desktop
data "azuread_service_principal" "spn" {
  client_id = "9cdead84-a844-4324-93f2-b2e6bb768d07"
}

data "azurerm_role_definition" "power_on_off_role" {
  name = "Desktop Virtualization Power On Off Contributor"
}

data "azurerm_role_definition" "power_on_role" {
  name = "Desktop Virtualization Power On Contributor"
}

# Get an existing built-in role definition
data "azurerm_role_definition" "this" {
  name = "Desktop Virtualization User"
}

# Get an existing Azure AD group that will be assigned to the application group
data "azuread_group" "existing" {
  count            = length(var.user_group_name) > 0 ? length(var.user_group_name) : 0
  display_name     = var.user_group_name[count.index]
  security_enabled = true
}
