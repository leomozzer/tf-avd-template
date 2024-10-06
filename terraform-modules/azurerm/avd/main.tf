# ############
# # Azure AD #
# ############

# resource "azuread_group" "admin_group_avd" {
#   display_name     = var.admin_group_avd_name
#   security_enabled = true
# }

# resource "azuread_group" "admin_reader_avd" {
#   display_name     = var.admin_reader_avd_name
#   security_enabled = true
# }

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

resource "azurerm_virtual_machine_extension" "avd_register_session_host" {
  count                = var.number_vms
  name                 = "RegisterSessionHost"
  virtual_machine_id   = length(azurerm_windows_virtual_machine.avd_vm_from_gallery_image) > 0 ? azurerm_windows_virtual_machine.avd_vm_from_gallery_image[count.index].id : azurerm_windows_virtual_machine.avd_vm[count.index].id
  publisher            = "Microsoft.Powershell"
  type                 = "DSC"
  type_handler_version = "2.83.5.0"

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

#Configure the path of the Azure File Share poiting to the FSLogix directory
# resource "azurerm_virtual_machine_extension" "configure_fslogix" {
#   count                = length(var.vm_extension_fslogix_sta_name) > 0 ? length(var.vm_extension_fslogix_fileshare_name) > 0 ? length(var.vm_extension_fslogix_directory_name) > 0 ? var.number_vms : 0 : 0 : 0
#   name                 = "ConfigureFsLogix"
#   virtual_machine_id   = length(azurerm_windows_virtual_machine.avd_vm_from_gallery_image) > 0 ? azurerm_windows_virtual_machine.avd_vm_from_gallery_image[count.index].id : azurerm_windows_virtual_machine.avd_vm[count.index].id
#   publisher            = "Microsoft.Compute"
#   type                 = "CustomScriptExtension"
#   type_handler_version = "1.9"

#   protected_settings = <<SETTINGS
#   {    
#     "commandToExecute": "powershell -command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${base64encode(data.template_file.ps_configure_fslogix_script.rendered)}')) | Out-File -filepath configfslogix.ps1\" && powershell -ExecutionPolicy Unrestricted -File configfslogix.ps1 -azureStaName ${var.vm_extension_fslogix_sta_name} -fileShareName ${var.vm_extension_fslogix_fileshare_name} -fsLogixDirectoryValue ${var.vm_extension_fslogix_directory_name} -domainName ${var.domain_name} -localAdminUser ${var.vm_admin_username}"
#   }
#   SETTINGS

#   depends_on = [azurerm_windows_virtual_machine.avd_vm]
# }

# #Configure AVD host deployed from a Golden Image
# resource "azurerm_virtual_machine_extension" "configure_host_golden_image" {
#   count                = length(var.vm_source_image_id) > 0 ? var.number_vms : 0
#   name                 = "configure-host-golden-image"
#   virtual_machine_id   = azurerm_windows_virtual_machine.avd_vm_from_gallery_image[count.index].id
#   publisher            = "Microsoft.Compute"
#   type                 = "CustomScriptExtension"
#   type_handler_version = "1.9"

#   protected_settings = <<SETTINGS
#   {    
#     "commandToExecute": "powershell -command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${base64encode(data.template_file.ps_script.rendered)}')) | Out-File -filepath script.ps1\" && powershell -ExecutionPolicy Unrestricted -File script.ps1 -fsLogixDirectoryValue ${var.fslogix_directory} -registrationTokenValue ${azurerm_virtual_desktop_host_pool_registration_info.avd.token}"
#   }
#   SETTINGS

#   depends_on = [azurerm_windows_virtual_machine.avd_vm_from_gallery_image]
# }

#Configure Time Zone on VM if needed
#Default Time zone is UTC
# resource "azurerm_virtual_machine_extension" "configure_timezone" {
#   count                = length(var.vm_extension_timezone_name) > 0 ? var.number_vms : 0
#   name                 = "ConfigureTimeZone"
#   virtual_machine_id   = azurerm_windows_virtual_machine.avd_vm_from_gallery_image[count.index].id
#   publisher            = "Microsoft.Compute"
#   type                 = "CustomScriptExtension"
#   type_handler_version = "1.9"

#   protected_settings = <<SETTINGS
#   {    
#     "commandToExecute": "powershell -command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${base64encode(data.template_file.ps_configure_timzone_script.rendered)}')) | Out-File -filepath timezone.ps1\" && powershell -ExecutionPolicy Unrestricted -File timezone.ps1 -timeZoneName ${var.vm_extension_timezone_name}"
#   }
#   SETTINGS

#   depends_on = [azurerm_windows_virtual_machine.avd_vm_from_gallery_image]
# }

#Configure the path of the Azure File Share poiting to the FSLogix directory
# resource "azurerm_virtual_machine_extension" "configure_fslogix" {
#   count                = length(var.vm_extension_fslogix_sta_name) > 0 ? length(var.vm_extension_fslogix_fileshare_name) > 0 ? length(var.vm_extension_fslogix_directory_name) > 0 ? var.number_vms : 0 : 0 : 0
#   name                 = "ConfigureFsLogix"
#   virtual_machine_id   = azurerm_windows_virtual_machine.avd_vm_from_gallery_image[count.index].id
#   publisher            = "Microsoft.Compute"
#   type                 = "CustomScriptExtension"
#   type_handler_version = "1.9"

#   protected_settings = <<SETTINGS
#   {    
#     "commandToExecute": "powershell -command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${base64encode(data.template_file.ps_configure_fslogix_script.rendered)}')) | Out-File -filepath configfslogix.ps1\" && powershell -ExecutionPolicy Unrestricted -File configfslogix.ps1 -azureStaName ${var.vm_extension_fslogix_sta_name} -fileShareName ${var.vm_extension_fslogix_fileshare_name} -fsLogixDirectoryValue ${var.vm_extension_fslogix_directory_name}"
#   }
#   SETTINGS

#   depends_on = [azurerm_windows_virtual_machine.avd_vm_from_gallery_image]
# }

#When host is deployed using a image from shared gallery, the host agent isn't proper configured
# resource "azurerm_virtual_machine_extension" "configure_host_agent" {
#   count                = length(var.vm_source_image_id) > 0 ? var.number_vms : 0
#   name                 = "ConfigureRdaAgent"
#   virtual_machine_id   = azurerm_windows_virtual_machine.avd_vm_from_gallery_image[count.index].id
#   publisher            = "Microsoft.Compute"
#   type                 = "CustomScriptExtension"
#   type_handler_version = "1.9"

#   protected_settings = <<SETTINGS
#   {    
#     "commandToExecute": "powershell -command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${base64encode(data.template_file.ps_configure_rdaagent_script.rendered)}')) | Out-File -filepath configrdaagent.ps1\" && powershell -ExecutionPolicy Unrestricted -File configrdaagent.ps1 -registrationTokenValue ${azurerm_virtual_desktop_host_pool_registration_info.avd.token}"
#   }
#   SETTINGS

#   depends_on = [azurerm_windows_virtual_machine.avd_vm_from_gallery_image]
# }

