resource "azurerm_resource_group" "rg_avd" {
  name     = local.resource_group_name
  location = var.location
}

resource "azurerm_virtual_desktop_host_pool" "avd" {
  name                = local.hostpool_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_avd.name

  type               = var.hostpool_type
  load_balancer_type = var.hostpool_load_balancer_type

  validate_environment = var.hostpool_validate_environment
  start_vm_on_connect  = var.hostpool_start_vm_on_connect

  maximum_sessions_allowed = var.hostpool_maximum_sessions_allowed

  preferred_app_group_type = var.preferred_app_group_type

  custom_rdp_properties = var.custom_rdp_properties

}

resource "azurerm_virtual_desktop_workspace" "avd" {
  depends_on          = [azurerm_virtual_desktop_host_pool.avd]
  name                = local.workspace_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_avd.name
}

resource "azurerm_virtual_desktop_application_group" "avd_desktop" {
  depends_on          = [azurerm_virtual_desktop_workspace.avd]
  count               = var.preferred_app_group_type == "Desktop" ? 1 : 0
  name                = local.desktop_application_group_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_avd.name

  type         = "Desktop"
  host_pool_id = azurerm_virtual_desktop_host_pool.avd.id
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "avd_desktop" {
  depends_on           = [azurerm_virtual_desktop_application_group.avd_desktop]
  count                = var.preferred_app_group_type == "Desktop" ? 1 : 0
  workspace_id         = azurerm_virtual_desktop_workspace.avd.id
  application_group_id = azurerm_virtual_desktop_application_group.avd_desktop[0].id
}

resource "time_rotating" "avd_registration_expiration" {
  # Must be between 1 hour and 30 days
  rotation_days = 15
}

resource "azurerm_virtual_desktop_host_pool_registration_info" "avd" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.avd.id
  expiration_date = time_rotating.avd_registration_expiration.rotation_rfc3339
}

module "hosts" {
  count      = var.number_of_hosts
  source     = "../session-hosts"
  depends_on = [azurerm_resource_group.rg_avd]

  resource_group_name                 = local.resource_group_name
  virtual_network_resource_group_name = var.virtual_network_resource_group_name
  virtual_network_name                = var.virtual_network_name
  subnet_name                         = var.subnet_name

  hostname_prefix = var.hostname_prefix

  number_of_hosts = var.number_of_hosts

  local_admin_username = var.local_admin_username
  local_admin_password = var.local_admin_password

  domain_type          = var.domain_type
  domain_name          = var.domain_name
  ou_path              = var.ou_path
  user_domain_join     = var.user_domain_join
  password_domain_join = var.password_domain_join

  virtual_desktop_host_pool_name               = azurerm_virtual_desktop_host_pool.avd.name
  virtual_desktop_host_pool_registration_token = azurerm_virtual_desktop_host_pool_registration_info.avd.token

}
