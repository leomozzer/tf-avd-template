
module "monitoring" {
  source          = "../terraform-modules/azurerm/monitoring"
  location        = var.principal_location
  location_prefix = local.region_name_standardize[var.principal_location]
}

# module "subscription_definition" {
#   source  = "gettek/policy-as-code/azurerm//modules/definition"
#   version = "2.8.0"
#   for_each = {
#     for index, definition in var.policy_definitions : definition.name => definition
#   }
#   management_group_id = data.azurerm_management_group.management_group.id
#   policy_name         = each.value.file_name
#   display_name        = (jsondecode(file("../policies/${each.value.category}/${each.value.file_name}.json"))).properties.displayName
#   policy_description  = (jsondecode(file("../policies/${each.value.category}/${each.value.file_name}.json"))).properties.description
#   policy_category     = (jsondecode(file("../policies/${each.value.category}/${each.value.file_name}.json"))).properties.metadata.category
#   policy_version      = (jsondecode(file("../policies/${each.value.category}/${each.value.file_name}.json"))).properties.metadata.version
#   policy_rule         = (jsondecode(file("../policies/${each.value.category}/${each.value.file_name}.json"))).properties.policyRule
#   policy_parameters   = (jsondecode(file("../policies/${each.value.category}/${each.value.file_name}.json"))).properties.parameters
#   policy_metadata     = (jsondecode(file("../policies/${each.value.category}/${each.value.file_name}.json"))).properties.metadata
# }

# ## Create Initiatives
# ## Use the following piece only if it's required to have a initiative

# locals {
#   initiative_list = flatten([
#     for index, initiative in var.initiative_definitions : {
#       "initiative" : {
#         "definitions" : [for definition in var.policy_definitions : module.subscription_definition[definition.name].definition if contains(initiative.definitions, definition.name) == true]
#         "initiative_name" : initiative.initiative_name
#         "initiative_display_name" : initiative.initiative_display_name
#         "initiative_category" : initiative.initiative_category
#         "initiative_description" : initiative.initiative_description
#         "assignment_effect" : initiative.assignment_effect
#         "skip_role_assignment"   = initiative.skip_role_assignment
#         "skip_remediation"       = initiative.skip_remediation
#         "re_evaluate_compliance" = initiative.re_evaluate_compliance
#         "module_index"           = index
#       }
#     }
#   ])
# }

# module "configure_initiative" {
#   source  = "gettek/policy-as-code/azurerm//modules/initiative"
#   version = "2.8.0"
#   for_each = {
#     for key, initiative in local.initiative_list : key => initiative
#   }
#   management_group_id     = data.azurerm_management_group.management_group.id
#   initiative_name         = each.value["initiative"]["initiative_name"]
#   initiative_display_name = "${each.value["initiative"]["initiative_category"]}: ${each.value["initiative"]["initiative_display_name"]}"
#   initiative_description  = each.value["initiative"]["initiative_description"]
#   initiative_category     = each.value["initiative"]["initiative_category"]

#   member_definitions = each.value["initiative"]["definitions"]
# }

# module "initiative_assignment" {
#   source  = "gettek/policy-as-code/azurerm//modules/set_assignment"
#   version = "2.8.0"
#   for_each = {
#     for key, initiative in local.initiative_list : key => initiative
#   }
#   assignment_scope  = data.azurerm_management_group.management_group.id
#   initiative        = module.configure_initiative[each.value["initiative"]["module_index"]].initiative
#   assignment_effect = each.value["initiative"]["assignment_effect"]

#   # resource remediation options
#   skip_role_assignment   = each.value["initiative"]["skip_role_assignment"]
#   skip_remediation       = each.value["initiative"]["skip_remediation"]
#   re_evaluate_compliance = each.value["initiative"]["re_evaluate_compliance"]
# }

# resource "random_uuid" "uuid_custom_role_avd_operator" {
# }

# resource "azurerm_role_definition" "custom_role_avd_operator" {
#   role_definition_id = random_uuid.uuid_custom_role_avd_operator.result
#   name               = "AVD Operator"
#   scope              = data.azurerm_management_group.management_group.id

#   permissions {
#     actions     = local.avd_operator_role_assignment_actions_definition
#     not_actions = []
#   }

#   assignable_scopes = [
#     data.azurerm_management_group.management_group.id
#   ]
# }

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
  spoke_resource_group_name         = var.rg_vnet_name
  spoke_vnet_name                   = var.vnet_name
  avd_vnet_name                     = var.snet_name
  number_vms                        = each.value.number_vms
  avdprefix                         = each.value.avdprefix
  environment                       = var.environment
  vm_admin_username                 = data.azurerm_key_vault_secret.vm_admin_username.value
  vm_admin_password                 = data.azurerm_key_vault_secret.vm_admin_password.value
  domain_type                       = var.domain_type
  domain_name                       = var.domain_name
  ou_path                           = each.value.ou_path
  user_domainjoin                   = data.azurerm_key_vault_secret.user_domainjoin.value
  password_domain_join              = data.azurerm_key_vault_secret.password_domain_join.value
  admin_group_avd_name              = each.value.add_admin_group_name
  admin_reader_avd_name             = each.value.add_reader_group_name
  operator_group_avd_name           = each.value.aad_operator_group_name

  ### Optional parameters
  vm_size            = "Standard_B4ms"
  vm_source_image_id = var.vm_source_image_id
  # data_collection_rule_id = module.monitoring.dcr.id
  enable_scaling_plan = false
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

  //depends_on = [module.monitoring]
}
