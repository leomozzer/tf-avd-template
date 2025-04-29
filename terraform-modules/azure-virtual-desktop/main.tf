resource "azurerm_resource_group" "rg_avd" {
  name     = local.resource_group_name
  location = var.location
}

resource "azurerm_virtual_desktop_host_pool" "avd_pooled" {
  count               = var.hostpool_type == "Pooled" ? 1 : 0
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

resource "azurerm_virtual_desktop_host_pool" "avd_personal" {
  count               = var.hostpool_type == "Personal" ? 1 : 0
  name                = local.hostpool_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_avd.name

  type               = var.hostpool_type
  load_balancer_type = var.hostpool_load_balancer_type

  validate_environment = var.hostpool_validate_environment
  start_vm_on_connect  = var.hostpool_start_vm_on_connect

  preferred_app_group_type = var.preferred_app_group_type

  custom_rdp_properties = var.custom_rdp_properties

}

resource "azurerm_monitor_diagnostic_setting" "hostpool_diagnostic_setting" {
  name                       = "avd-diagnostic-setting"
  target_resource_id         = var.hostpool_type == "Personal" ? azurerm_virtual_desktop_host_pool.avd_personal[0].id : azurerm_virtual_desktop_host_pool.avd_pooled[0].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "Checkpoint"
  }
  enabled_log {
    category = "Error"
  }
  enabled_log {
    category = "Management"
  }
  enabled_log {
    category = "Connection"
  }
  enabled_log {
    category = "HostRegistration"
  }
  enabled_log {
    category = "AgentHealthStatus"
  }
  enabled_log {
    category = "NetworkData"
  }
  enabled_log {
    category = "ConnectionGraphicsData"
  }
  enabled_log {
    category = "SessionHostManagement"
  }
  enabled_log {
    category = "AutoscaleEvaluationPooled"
  }
}

resource "azurerm_virtual_desktop_workspace" "avd" {
  depends_on          = [azurerm_virtual_desktop_host_pool.avd_pooled, azurerm_virtual_desktop_host_pool.avd_personal]
  name                = local.workspace_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_avd.name
}

resource "azurerm_monitor_diagnostic_setting" "workspace_diagnostic_setting" {
  name                       = "avd-diagnostic-setting"
  target_resource_id         = azurerm_virtual_desktop_workspace.avd.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "Checkpoint"
  }
  enabled_log {
    category = "Error"
  }
  enabled_log {
    category = "Management"
  }
  enabled_log {
    category = "Feed"
  }
}

resource "azurerm_virtual_desktop_application_group" "avd_desktop" {
  depends_on          = [azurerm_virtual_desktop_workspace.avd]
  count               = var.preferred_app_group_type == "Desktop" ? 1 : 0
  name                = local.desktop_application_group_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_avd.name

  type         = "Desktop"
  host_pool_id = var.hostpool_type == "Personal" ? azurerm_virtual_desktop_host_pool.avd_personal[0].id : azurerm_virtual_desktop_host_pool.avd_pooled[0].id
}

resource "azurerm_monitor_diagnostic_setting" "desktop_ag_diagnostic_setting" {
  count                      = var.preferred_app_group_type == "Desktop" ? 1 : 0
  name                       = "avd-diagnostic-setting"
  target_resource_id         = azurerm_virtual_desktop_application_group.avd_desktop[count.index].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "Checkpoint"
  }
  enabled_log {
    category = "Error"
  }
  enabled_log {
    category = "Management"
  }
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "avd_desktop" {
  depends_on           = [azurerm_virtual_desktop_application_group.avd_desktop]
  count                = var.preferred_app_group_type == "Desktop" ? 1 : 0
  workspace_id         = azurerm_virtual_desktop_workspace.avd.id
  application_group_id = azurerm_virtual_desktop_application_group.avd_desktop[0].id
}

# Assign the Azure AD group to the application group
resource "azurerm_role_assignment" "this" {
  count                            = length(var.user_group_name) > 0 ? length(var.user_group_name) : 0
  principal_id                     = data.azuread_group.existing[count.index].object_id
  scope                            = azurerm_virtual_desktop_application_group.avd_desktop[0].id
  role_definition_id               = data.azurerm_role_definition.this.id
  skip_service_principal_aad_check = false
}


# Assign the Azure AD group to the application group
resource "azurerm_role_assignment" "power_on" {
  count                            = length(var.user_group_name) > 0 ? length(var.user_group_name) : 0
  principal_id                     = data.azuread_group.existing[count.index].object_id
  scope                            = azurerm_resource_group.rg_avd.id
  role_definition_id               = data.azurerm_role_definition.power_on_role.id
  skip_service_principal_aad_check = false
}

resource "time_rotating" "avd_registration_expiration" {
  # Must be between 1 hour and 30 days
  rotation_days = 15
}

resource "azurerm_virtual_desktop_host_pool_registration_info" "avd" {
  hostpool_id     = var.hostpool_type == "Personal" ? azurerm_virtual_desktop_host_pool.avd_personal[0].id : azurerm_virtual_desktop_host_pool.avd_pooled[0].id
  expiration_date = time_rotating.avd_registration_expiration.rotation_rfc3339
}

# Availability Set
resource "azurerm_availability_set" "aset" {
  location                     = azurerm_resource_group.rg_avd.location
  name                         = local.availability_set_name
  resource_group_name          = azurerm_resource_group.rg_avd.name
  managed                      = true
  platform_fault_domain_count  = 2
  platform_update_domain_count = 5
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

  virtual_desktop_host_pool_name               = var.hostpool_type == "Personal" ? azurerm_virtual_desktop_host_pool.avd_personal[0].id : azurerm_virtual_desktop_host_pool.avd_pooled[0].id
  virtual_desktop_host_pool_registration_token = azurerm_virtual_desktop_host_pool_registration_info.avd.token

  source_image_version_id = var.source_image_version_id

  data_collection_rule_id = var.data_collection_rule_id

  availability_set_id = azurerm_availability_set.aset.id

  #Optional
  virtual_machine_size = var.virtual_machine_size

}

# Assign the Azure AD group to the application group
resource "azurerm_role_assignment" "scaling_plan" {
  principal_id       = data.azuread_service_principal.spn.object_id
  scope              = azurerm_resource_group.rg_avd.id
  role_definition_id = data.azurerm_role_definition.power_on_off_role.id
}

module "scaling_plan" {
  source                                           = "Azure/avm-res-desktopvirtualization-scalingplan/azurerm"
  enable_telemetry                                 = true
  version                                          = "0.1.2"
  virtual_desktop_scaling_plan_name                = local.scaling_plan_name
  virtual_desktop_scaling_plan_location            = azurerm_resource_group.rg_avd.location
  virtual_desktop_scaling_plan_resource_group_name = azurerm_resource_group.rg_avd.name
  virtual_desktop_scaling_plan_time_zone           = "Eastern Standard Time"
  virtual_desktop_scaling_plan_description         = "${var.avd_name} Scaling Plan"
  #  virtual_desktop_scaling_plan_tags                = local.tags
  virtual_desktop_scaling_plan_host_pool = toset(
    [
      {
        hostpool_id          = var.hostpool_type == "Personal" ? azurerm_virtual_desktop_host_pool.avd_personal[0].id : azurerm_virtual_desktop_host_pool.avd_pooled[0].id
        scaling_plan_enabled = true
      }
    ]
  )
  virtual_desktop_scaling_plan_schedule = var.virtual_desktop_scaling_plan_schedule
}
