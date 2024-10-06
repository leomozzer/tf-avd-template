data "azurerm_subnet" "snet" {
  name                 = var.avd_vnet_name
  resource_group_name  = var.spoke_resource_group_name
  virtual_network_name = var.spoke_vnet_name
}

data "template_file" "ps_configure_timzone_script" {
  depends_on = [azurerm_virtual_desktop_host_pool_registration_info.avd]
  template   = file("../azure/scripts/PS-AVD-ConfigureTimeZone.ps1")
  vars = {
    timeZoneName = "${var.vm_extension_timezone_name}"
  }
}

data "template_file" "ps_configure_fslogix_script" {
  depends_on = [azurerm_virtual_desktop_host_pool_registration_info.avd]
  template   = file("../azure/scripts/PS-AVD-ConfigureFSLogixFileShare.ps1")
  vars = {
    vm_extension_fslogix_sta_name       = "${var.vm_extension_fslogix_sta_name}"
    vm_extension_fslogix_fileshare_name = "${var.vm_extension_fslogix_fileshare_name}"
    vm_extension_fslogix_directory_name = "${var.vm_extension_fslogix_directory_name}"
    domain_name                         = "${var.domain_name}"
    vm_admin_username                   = "${var.vm_admin_username}"
  }
}

data "template_file" "ps_configure_rdaagent_script" {
  depends_on = [azurerm_virtual_desktop_host_pool_registration_info.avd]
  template   = file("../azure/scripts/PS-AVD-ConfigureRDAAgent.ps1")
  vars = {
    registrationTokenValue = "${azurerm_virtual_desktop_host_pool_registration_info.avd.token}"
  }
}

# data "azurerm_shared_image_versions" "shared_gallery" {
#   count               = length(var.shared_image_definition.image_name) > 0 ? 1 : 0
#   image_name          = var.shared_image_definition.image_name
#   gallery_name        = var.shared_image_definition.gallery_name
#   resource_group_name = var.shared_image_definition.resource_group_name
# }

