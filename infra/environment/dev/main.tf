###########################################
# Creating the monitoring resources first #
###########################################

module "monitoring" {
  source          = "../../modules/monitoring"
  location        = var.principal_location
  location_prefix = local.region_name_standardize[var.principal_location]
}

module "avd" {
  source = "../../modules/azure-virtual-desktop"

  virtual_network_resource_group_name = var.rg_vnet_name
  virtual_network_name                = var.vnet_name
  subnet_name                         = var.snet_name
  local_admin_username                = "sometest"
  local_admin_password                = "pwd123!"
  avd_name                            = var.hostname_prefix

  number_of_hosts         = var.number_of_hosts
  source_image_version_id = var.vm_source_image_id

  environment_name     = var.environment
  hostname_prefix      = var.hostname_prefix
  domain_type          = var.domain_type
  domain_name          = var.domain_name
  ou_path              = var.ou_path
  user_domain_join     = data.azurerm_key_vault_secret.user_domainjoin.value
  password_domain_join = data.azurerm_key_vault_secret.password_domain_join.value

  user_group_name              = ["AVD_Desktop", "AVD_RemoteApp", "AVD_Entra_ID"]
  hostpool_start_vm_on_connect = true

  virtual_machine_size = "Standard_B4ms"

  hostpool_type = "Pooled"

  log_analytics_workspace_id = module.monitoring.log_analytics_workspace.id

  virtual_desktop_scaling_plan_schedule = toset(
    [
      {
        name                                 = "Weekday"
        days_of_week                         = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
        ramp_up_start_time                   = "09:00"
        ramp_up_load_balancing_algorithm     = "BreadthFirst"
        ramp_up_minimum_hosts_percent        = 50
        ramp_up_capacity_threshold_percent   = 80
        peak_start_time                      = "10:00"
        peak_load_balancing_algorithm        = "DepthFirst"
        ramp_down_start_time                 = "17:00"
        ramp_down_load_balancing_algorithm   = "BreadthFirst"
        ramp_down_minimum_hosts_percent      = 50
        ramp_down_force_logoff_users         = true
        ramp_down_wait_time_minutes          = 15
        ramp_down_notification_message       = "The session will end in 15 minutes."
        ramp_down_capacity_threshold_percent = 50
        ramp_down_stop_hosts_when            = "ZeroActiveSessions"
        off_peak_start_time                  = "18:00"
        off_peak_load_balancing_algorithm    = "BreadthFirst"
      }
    ]
  )
}
