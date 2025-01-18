# ############
# # Azure AD #
# ############

resource "azuread_group" "admin_group_avd" {
  display_name     = var.admin_group_avd_name
  security_enabled = true
}

resource "azurerm_role_assignment" "avd_admin_group" {
  scope                = azurerm_resource_group.rg_avd.id
  role_definition_name = "Contributor"
  principal_id         = azuread_group.admin_group_avd.object_id
  depends_on           = [azurerm_resource_group.rg_avd]
}

resource "azuread_group" "reader_group_avd" {
  display_name     = var.admin_reader_avd_name
  security_enabled = true
}

resource "azurerm_role_assignment" "avd_reader_group" {
  scope                = azurerm_resource_group.rg_avd.id
  role_definition_name = "Reader"
  principal_id         = azuread_group.reader_group_avd.object_id
  depends_on           = [azurerm_resource_group.rg_avd]
}

resource "azuread_group" "operator_group_avd" {
  display_name     = var.operator_group_avd_name
  security_enabled = true
}

resource "azurerm_role_assignment" "avd_operator_role_assignment" {
  scope                = azurerm_resource_group.rg_avd.id
  role_definition_name = "AVD Operator"
  principal_id         = azuread_group.operator_group_avd.object_id
  depends_on           = [azurerm_resource_group.rg_avd]
}

# ##################
# # Infrastructure #
# ##################

resource "azurerm_resource_group" "rg_avd" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    VnetRgName = var.spoke_resource_group_name
    VnetName   = var.spoke_vnet_name
  }
}

resource "azurerm_virtual_desktop_host_pool" "avd" {
  name                = var.hostpool_name
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

resource "time_rotating" "avd_registration_expiration" {
  # Must be between 1 hour and 30 days
  rotation_days = 15
}

resource "azurerm_virtual_desktop_host_pool_registration_info" "avd" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.avd.id
  expiration_date = time_rotating.avd_registration_expiration.rotation_rfc3339
}

resource "azurerm_virtual_desktop_workspace" "avd" {
  depends_on          = [azurerm_virtual_desktop_host_pool_registration_info.avd]
  name                = var.workspace_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_avd.name
}

resource "azurerm_virtual_desktop_application_group" "avd_desktop" {
  depends_on          = [azurerm_virtual_desktop_workspace.avd]
  count               = var.preferred_app_group_type == "Desktop" ? 1 : 0
  name                = "desktop-vdag"
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

resource "azurerm_virtual_desktop_application_group" "remote_app" {
  count               = var.preferred_app_group_type == "RailApplications" ? length(var.application_list) > 0 ? length(var.application_list) : 0 : 0
  name                = var.application_list[count.index].name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_avd.name

  type          = "RemoteApp"
  host_pool_id  = azurerm_virtual_desktop_host_pool.avd.id
  friendly_name = var.application_list[count.index].friendly_name

  tags = {
    "key" = length(var.application_list)
  }

}

resource "azurerm_network_interface" "avd_vm_nic" {
  count               = var.number_vms
  name                = "${var.avdprefix}-${count.index + 1}-nic"
  resource_group_name = azurerm_resource_group.rg_avd.name
  location            = var.location

  ip_configuration {
    name                          = "nic${count.index + 1}_config"
    subnet_id                     = data.azurerm_subnet.snet.id
    private_ip_address_allocation = "Dynamic"
  }

  depends_on = [
    azurerm_resource_group.rg_avd
  ]
}

#################################################
# Deploying VMs with standard images from Azure #
#################################################

resource "azurerm_windows_virtual_machine" "avd_vm" {
  count                 = length(var.vm_source_image_id) == 0 ? var.number_vms : 0
  name                  = "${var.avdprefix}-${count.index + 1}"
  resource_group_name   = azurerm_resource_group.rg_avd.name
  location              = var.location
  size                  = var.vm_size
  network_interface_ids = ["${azurerm_network_interface.avd_vm_nic.*.id[count.index]}"]
  provision_vm_agent    = true
  admin_username        = var.vm_admin_username
  admin_password        = var.vm_admin_password

  os_disk {
    name                 = "${var.avdprefix}-${count.index + 1}"
    caching              = var.os_disk_caching
    storage_account_type = var.os_disk_storage_account_type
  }

  timezone = length(var.vm_extension_timezone_name) > 0 ? var.vm_extension_timezone_name : "UTC"

  source_image_reference {
    publisher = var.source_image_reference_publisher
    offer     = var.source_image_reference_offer
    sku       = var.source_image_reference_sku
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  secure_boot_enabled = true

  depends_on = [
    azurerm_resource_group.rg_avd,
    azurerm_network_interface.avd_vm_nic
  ]

  tags = var.vm_tags
}

####################################
# Deploying VMs with gallery image #
####################################

resource "azurerm_windows_virtual_machine" "avd_vm_from_gallery_image" {
  count                 = length(var.vm_source_image_id) > 0 ? var.number_vms : 0
  name                  = "${var.avdprefix}-${count.index + 1}"
  resource_group_name   = azurerm_resource_group.rg_avd.name
  location              = var.location
  size                  = var.vm_size
  network_interface_ids = ["${azurerm_network_interface.avd_vm_nic.*.id[count.index]}"]
  provision_vm_agent    = true
  admin_username        = var.vm_admin_username
  admin_password        = var.vm_admin_password

  os_disk {
    name                 = "${var.avdprefix}-${count.index + 1}"
    caching              = var.os_disk_caching
    storage_account_type = var.os_disk_storage_account_type
  }

  timezone = length(var.vm_extension_timezone_name) > 0 ? var.vm_extension_timezone_name : "UTC"

  identity {
    type = "SystemAssigned"
  }

  secure_boot_enabled = true

  source_image_id = var.vm_source_image_id
  depends_on = [
    azurerm_resource_group.rg_avd,
    azurerm_network_interface.avd_vm_nic
  ]

  tags = var.vm_tags
}

#https://pixelrobots.co.uk/2019/03/use-terraform-to-join-a-new-azure-virtual-machine-to-a-domain/
resource "azurerm_virtual_machine_extension" "joindomain" {
  count                      = length(var.domain_type) > 0 ? var.number_vms : 0
  name                       = "JoinDomain"
  virtual_machine_id         = length(azurerm_windows_virtual_machine.avd_vm_from_gallery_image) > 0 ? azurerm_windows_virtual_machine.avd_vm_from_gallery_image[count.index].id : azurerm_windows_virtual_machine.avd_vm[count.index].id
  publisher                  = "Microsoft.Compute"
  type                       = "JsonADDomainExtension"
  type_handler_version       = "1.3"
  auto_upgrade_minor_version = true

  settings = <<-SETTINGS
    {
      "Name": "${var.domain_name}",
      "OUPath": "${var.ou_path}",
      "User": "${var.domain_name}\\${var.user_domainjoin}",
      "Restart": "true",
      "Options": "3"
    }
    SETTINGS

  protected_settings = <<-PROTECTED_SETTINGS
    {
      "Password": "${var.password_domain_join}"
    }
    PROTECTED_SETTINGS

  lifecycle {
    ignore_changes = [settings, protected_settings]
  }

  depends_on = [
    azurerm_windows_virtual_machine.avd_vm_from_gallery_image,
    azurerm_windows_virtual_machine.avd_vm
  ]
}

##################
# VMs Extensions #
##################

resource "azurerm_virtual_machine_extension" "avd_register_session_host" {
  count                = var.number_vms
  name                 = "RegisterSessionHost"
  virtual_machine_id   = length(azurerm_windows_virtual_machine.avd_vm_from_gallery_image) > 0 ? azurerm_windows_virtual_machine.avd_vm_from_gallery_image[count.index].id : azurerm_windows_virtual_machine.avd_vm[count.index].id
  publisher            = "Microsoft.Powershell"
  type                 = "DSC"
  type_handler_version = "2.83"

  settings = <<-SETTINGS
    {
      "modulesUrl": "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_1.0.02721.349.zip",
      "configurationFunction": "Configuration.ps1\\AddSessionHost",
      "properties": {
        "hostPoolName": "${azurerm_virtual_desktop_host_pool.avd.name}",
        "aadJoin": false
      }
    }
    SETTINGS

  protected_settings = <<-PROTECTED_SETTINGS
    {
      "properties": {
        "registrationInfoToken": "${azurerm_virtual_desktop_host_pool_registration_info.avd.token}"
      }
    }
    PROTECTED_SETTINGS

  lifecycle {
    ignore_changes = [settings, protected_settings]
  }

  depends_on = [azurerm_virtual_machine_extension.joindomain]
}

resource "azurerm_virtual_machine_extension" "ama" {
  count                = var.number_vms
  name                 = "AzureMonitorWindowsAgent"
  virtual_machine_id   = length(azurerm_windows_virtual_machine.avd_vm_from_gallery_image) > 0 ? azurerm_windows_virtual_machine.avd_vm_from_gallery_image[count.index].id : azurerm_windows_virtual_machine.avd_vm[count.index].id
  publisher            = "Microsoft.Azure.Monitor"
  type                 = "AzureMonitorWindowsAgent"
  type_handler_version = "1.30"
}

########################
# Data collection Rule #
########################

resource "azurerm_monitor_data_collection_rule_association" "dcr" {
  count                   = length(var.data_collection_rule_id) > 0 ? var.number_vms : 0
  name                    = "dcr-${var.avdprefix}-${count.index + 1}"
  target_resource_id      = length(azurerm_windows_virtual_machine.avd_vm_from_gallery_image) > 0 ? azurerm_windows_virtual_machine.avd_vm_from_gallery_image[count.index].id : azurerm_windows_virtual_machine.avd_vm[count.index].id
  data_collection_rule_id = var.data_collection_rule_id
  depends_on = [
    azurerm_windows_virtual_machine.avd_vm_from_gallery_image,
    azurerm_windows_virtual_machine.avd_vm
  ]
}

################
# Scaling Plan #
################

resource "random_uuid" "uuid" {
}

resource "azurerm_role_definition" "role_definition" {
  count       = var.enable_scaling_plan == true ? 1 : 0
  name        = "AVD-AutoScale"
  scope       = azurerm_resource_group.rg_avd.id
  description = "AVD AutoScale Role"
  permissions {
    actions     = local.avd_autoscale_actions_definition
    not_actions = []
  }
  assignable_scopes = [
    azurerm_resource_group.rg_avd.id,
  ]
}

resource "azurerm_role_assignment" "role_assignment" {
  count                            = var.enable_scaling_plan == true ? 1 : 0
  name                             = random_uuid.uuid.result
  scope                            = azurerm_resource_group.rg_avd.id
  role_definition_id               = azurerm_role_definition.role_definition[count.index].role_definition_resource_id
  principal_id                     = data.azuread_service_principal.avd_sp[count.index].object_id
  skip_service_principal_aad_check = true
}

resource "azurerm_virtual_desktop_scaling_plan" "example" {
  count               = var.enable_scaling_plan == true ? 1 : 0
  name                = "scaling-plan-${var.hostpool_name}"
  location            = azurerm_resource_group.rg_avd.location
  resource_group_name = azurerm_resource_group.rg_avd.name
  friendly_name       = "Scaling Plan of ${var.hostpool_name}"
  time_zone           = "GMT Standard Time"
  schedule {
    name                                 = "Weekdays"
    days_of_week                         = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
    ramp_up_start_time                   = "05:00"
    ramp_up_load_balancing_algorithm     = "BreadthFirst"
    ramp_up_minimum_hosts_percent        = 20
    ramp_up_capacity_threshold_percent   = 10
    peak_start_time                      = "09:00"
    peak_load_balancing_algorithm        = "BreadthFirst"
    ramp_down_start_time                 = "19:00"
    ramp_down_load_balancing_algorithm   = "DepthFirst"
    ramp_down_minimum_hosts_percent      = 10
    ramp_down_force_logoff_users         = false
    ramp_down_wait_time_minutes          = 45
    ramp_down_notification_message       = "Please log off in the next 45 minutes..."
    ramp_down_capacity_threshold_percent = 5
    ramp_down_stop_hosts_when            = "ZeroActiveSessions"
    off_peak_start_time                  = "22:00"
    off_peak_load_balancing_algorithm    = "DepthFirst"
  }
  host_pool {
    hostpool_id          = azurerm_virtual_desktop_host_pool.avd.id
    scaling_plan_enabled = true
  }
  depends_on = [azurerm_virtual_desktop_host_pool.avd, azurerm_role_assignment.role_assignment]
}
