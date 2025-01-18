#Just a test
module "avd" {
  source = "../terraform-modules/azure-virtual-desktop"

  virtual_network_resource_group_name = var.rg_vnet_name
  virtual_network_name                = var.vnet_name
  subnet_name                         = var.snet_name
  local_admin_username                = data.azurerm_key_vault_secret.vm_admin_username.value
  local_admin_password                = data.azurerm_key_vault_secret.vm_admin_password.value

  hostname_prefix      = var.hostname_prefix
  domain_type          = var.domain_type
  domain_name          = var.domain_name
  ou_path              = "OU=Servers,OU=AVDInfra,OU=AzureADConnect,DC=lsolab,DC=com"
  user_domain_join     = data.azurerm_key_vault_secret.user_domainjoin.value
  password_domain_join = data.azurerm_key_vault_secret.password_domain_join.value
}
