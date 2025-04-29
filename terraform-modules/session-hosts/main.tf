#################
# Creating NICs #
#################
resource "azurerm_network_interface" "avd_vm_nic" {
  count               = var.number_of_hosts
  name                = "${var.hostname_prefix}-${count.index + 1}-nic"
  resource_group_name = var.resource_group_name
  location            = var.location

  ip_configuration {
    name                          = "nic${count.index + 1}_config"
    subnet_id                     = data.azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

###################################
#Deploying VMs with gallery image #
###################################

resource "azurerm_windows_virtual_machine" "avd_vm_from_gallery_image" {
  count                 = length(var.source_image_version_id) > 0 ? var.number_of_hosts : 0
  name                  = "${var.hostname_prefix}-${count.index + 1}"
  resource_group_name   = var.resource_group_name
  location              = var.location
  size                  = var.virtual_machine_size
  network_interface_ids = ["${azurerm_network_interface.avd_vm_nic.*.id[count.index]}"]
  provision_vm_agent    = true
  admin_username        = var.local_admin_username
  admin_password        = var.local_admin_password

  os_disk {
    name                 = "${var.hostname_prefix}-${count.index + 1}_OsDisk"
    caching              = var.os_disk_caching
    storage_account_type = var.os_disk_storage_account_type
  }

  timezone = var.virtual_machine_timezone_name

  identity {
    type = "SystemAssigned"
  }

  secure_boot_enabled = true

  source_image_id = var.source_image_version_id
  depends_on = [
    azurerm_network_interface.avd_vm_nic
  ]
}

#################################################
# Deploying VMs with standard images from Azure #
#################################################

resource "azurerm_windows_virtual_machine" "avd_vm" {
  count                 = length(var.source_image_version_id) == 0 ? var.number_of_hosts : 0
  name                  = "${var.hostname_prefix}-${count.index + 1}"
  resource_group_name   = var.resource_group_name
  location              = var.location
  size                  = var.virtual_machine_size
  network_interface_ids = ["${azurerm_network_interface.avd_vm_nic.*.id[count.index]}"]
  provision_vm_agent    = true
  admin_username        = var.local_admin_username
  admin_password        = var.local_admin_password

  os_disk {
    name                 = "${var.hostname_prefix}-${count.index + 1}_OsDisk"
    caching              = var.os_disk_caching
    storage_account_type = var.os_disk_storage_account_type
  }

  timezone = var.virtual_machine_timezone_name

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
    azurerm_network_interface.avd_vm_nic
  ]

  availability_set_id = var.availability_set_id
}

##################
# VMs Extensions #
##################

#https://pixelrobots.co.uk/2019/03/use-terraform-to-join-a-new-azure-virtual-machine-to-a-domain/
#Domain Join
resource "azurerm_virtual_machine_extension" "domain_join" {
  count                      = var.domain_type == "ADDS" ? var.number_of_hosts : 0
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
      "User": "${var.domain_name}\\${var.user_domain_join}",
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

# Installing DSC and adding host to the pool
resource "azurerm_virtual_machine_extension" "vmext_dsc" {
  count                = var.number_of_hosts
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
        "hostPoolName": "${var.virtual_desktop_host_pool_name}",
        "aadJoin": false
      }
    }
    SETTINGS

  protected_settings = <<-PROTECTED_SETTINGS
    {
      "properties": {
        "registrationInfoToken": "${var.virtual_desktop_host_pool_registration_token}"
      }
    }
    PROTECTED_SETTINGS

  lifecycle {
    ignore_changes = [settings, protected_settings]
  }

  depends_on = [azurerm_virtual_machine_extension.domain_join]
}

# Azure Monitoring Agent
resource "azurerm_virtual_machine_extension" "ama" {
  count                = var.number_of_hosts
  name                 = "AzureMonitorWindowsAgent"
  virtual_machine_id   = length(azurerm_windows_virtual_machine.avd_vm_from_gallery_image) > 0 ? azurerm_windows_virtual_machine.avd_vm_from_gallery_image[count.index].id : azurerm_windows_virtual_machine.avd_vm[count.index].id
  publisher            = "Microsoft.Azure.Monitor"
  type                 = "AzureMonitorWindowsAgent"
  type_handler_version = "1.30"

  depends_on = [
    azurerm_windows_virtual_machine.avd_vm_from_gallery_image,
    azurerm_windows_virtual_machine.avd_vm
  ]
}

# Data Collection rule connection with host
resource "azurerm_monitor_data_collection_rule_association" "dcr_avdi" {
  count                   = length(var.data_collection_rule_id) > 0 ? var.number_of_hosts : 0
  name                    = "dcr-avdi-${var.hostname_prefix}-${count.index + 1}"
  target_resource_id      = length(azurerm_windows_virtual_machine.avd_vm_from_gallery_image) > 0 ? azurerm_windows_virtual_machine.avd_vm_from_gallery_image[count.index].id : azurerm_windows_virtual_machine.avd_vm[count.index].id
  data_collection_rule_id = var.data_collection_rule_id
  depends_on = [
    azurerm_windows_virtual_machine.avd_vm_from_gallery_image,
    azurerm_windows_virtual_machine.avd_vm
  ]
}

# Virtual Machine Extension for Microsoft Antimalware
resource "azurerm_virtual_machine_extension" "mal" {
  count = var.number_of_hosts

  name                       = "IaaSAntimalware"
  publisher                  = "Microsoft.Azure.Security"
  type                       = "IaaSAntimalware"
  type_handler_version       = "1.3"
  virtual_machine_id         = length(azurerm_windows_virtual_machine.avd_vm_from_gallery_image) > 0 ? azurerm_windows_virtual_machine.avd_vm_from_gallery_image[count.index].id : azurerm_windows_virtual_machine.avd_vm[count.index].id
  auto_upgrade_minor_version = "true"

  depends_on = [
    azurerm_virtual_machine_extension.domain_join,
    azurerm_virtual_machine_extension.vmext_dsc,
    azurerm_virtual_machine_extension.ama
  ]
}
