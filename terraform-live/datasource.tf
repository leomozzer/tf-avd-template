data "azurerm_client_config" "current" {}

### Optional parameters
data "azurerm_key_vault" "vm_keyvault" {
  name                = var.key_vault_name
  resource_group_name = var.key_vault_resource_group
}

data "azurerm_key_vault_secret" "vm_admin_username" {
  key_vault_id = data.azurerm_key_vault.vm_keyvault.id
  name         = "vm-avda-admin-username-${var.environment}"
}

data "azurerm_key_vault_secret" "vm_admin_password" {
  key_vault_id = data.azurerm_key_vault.vm_keyvault.id
  name         = "vm-avd-admin-password-${var.environment}"
}

data "azurerm_key_vault_secret" "user_domainjoin" {
  key_vault_id = data.azurerm_key_vault.vm_keyvault.id
  name         = "domain-username"
}

data "azurerm_key_vault_secret" "password_domain_join" {
  key_vault_id = data.azurerm_key_vault.vm_keyvault.id
  name         = "domain-password"
}
