module "avd" {
  for_each = {
    for index, identifier in local.default_avd_definition : index => identifier
  }
  source = "../terraform-modules/azurerm/avd"
  providers = {
    azurerm = azurerm
  }
  resource_group_name               = "${each.value.resource_group_name}-${each.value.number_id}"
  location                          = each.value.location
  hostpool_name                     = each.value.avd_vdpool_name
  hostpool_type                     = each.value.hostpool_type
  hostpool_load_balancer_type       = each.value.load_balancer_type
  hostpool_maximum_sessions_allowed = each.value.maximum_sessions_allowed
  workspace_name                    = each.value.avd_workspace_name
  preferred_app_group_type          = each.value.avd_app_group_type
  application_list                  = each.value.application_list
  spoke_resource_group_name         = ""
  spoke_vnet_name                   = ""
  avd_vnet_name                     = ""
  number_vms                        = each.value.number_vms
  avdprefix                         = each.value.avdprefix
  environment                       = var.environment
  vm_admin_username                 = ""
  vm_admin_password                 = ""
  domain_type                       = var.domain_type
  domain_name                       = var.domain_name
  ou_path                           = each.value.ou_path
  user_domainjoin                   = ""
  password_domain_join              = "" #AJM6Z!0nv#FDqS!

  ### Optional parameters
  vm_size            = "Standard_B4ms"
  vm_source_image_id = ""
  # vm_source_image_id                  = var.vm_source_image_id
  # os_disk_storage_account_type = "Premium_LRS"
  custom_rdp_properties = var.custom_rdp_properties
  vm_tags               = var.vm_tags
  #source_image_reference_offer = "Windows-11"     #Just Win11
  #source_image_reference_sku   = "win11-23h2-avd" #Just Win11
  #source_image_reference_offer = "Office-365"  #Win11 + 365Apps
  #source_image_reference_sku = "win11-23h2-avd-m365" #Win11 + 365Apps

  #vm_extension_fslogix_directory_name = "prod"
  #vm_extension_fslogix_fileshare_name = "profiles"
  #vm_extension_fslogix_sta_name       = "lsoprofiles01"

  # vm_extension_fslogix_sta_name       = var.fslogix_sta_name
  # vm_extension_fslogix_fileshare_name = each.value.fslogix_fileshare_name
  # vm_extension_fslogix_directory_name = var.fslogix_directory
}
