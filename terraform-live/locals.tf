#######################
#    Commom locals    #
#######################

locals {
  region_name_standardize = {
    "East US"           = "eus"
    "eastus"            = "eus"
    "east us"           = "eus"
    "West US"           = "wus"
    "North Central US"  = "ncus"
    "South Central US"  = "scus"
    "East US 2"         = "eus2"
    "West US 2"         = "wus2"
    "Central US"        = "cus"
    "West Central US"   = "wcus"
    "Canada East"       = "canadaeast"
    "Canada Central"    = "canadacentral"
    "West Europe"       = "weu"
    "westeurope"        = "weu"
    "west europe"       = "weu"
    "North Europe"      = "neu"
    "northeurope"       = "neu"
    "UK South"          = "uks"
    "UK West"           = "ukw"
    "France Central"    = "francecentral"
    "France South"      = "francesouth"
    "Germany North"     = "germanynorth"
    "Germany West"      = "germanywest"
    "Switzerland North" = "swnorth"
    "Switzerland West"  = "swwest"
    "Norway East"       = "noeast"
    "Norway West"       = "nowest"
    # Add more mappings as needed
  }
}

########################
#   AVD local naming   #
########################

locals {
  default_fslogix_definition = flatten([
    for i, key in var.avd_definition : {
      index               = i
      location            = key["location"] != "" ? key["location"] : var.principal_location
      sta_fslogix_name    = "fslx${var.customershort_name}${i > 9 ? "${i + 1}" : "0${i + 1}"}"
      resource_group_name = "rg-avd-${local.region_name_standardize[key["location"] != "" ? key["location"] : var.principal_location]}-fslx${var.customershort_name}${i > 9 ? "${i + 1}" : "0${i + 1}"}-${var.environment}"
    }
  ])
}
locals {
  default_avd_definition = flatten([
    for i, key in var.avd_definition : [
      for j, identifier in key["identifier"] : {
        resource_group_identifier = "${i}${j > 9 ? "${j + 1}" : "0${j + 1}"}"
        subscription_id           = key["subscription_id"]
        name                      = "avd-${local.region_name_standardize[key["location"] != "" ? key["location"] : var.principal_location]}-${identifier["name"]}-${var.environment}"
        resource_group_name       = "rg-avd-${local.region_name_standardize[key["location"] != "" ? key["location"] : var.principal_location]}-${identifier["name"]}-${var.environment}"
        location                  = key["location"] != "" ? key["location"] : var.principal_location
        number_id                 = "${i}${j > 9 ? "${j + 1}" : "0${j + 1}"}"
        avd_vdpool_name           = "vdpool-avd${identifier["name"]}-${var.environment}"
        avd_workspace_name        = "vdws-${identifier["name"]}-${var.environment}"
        avd_app_group_type        = identifier["app_group_type"]
        hosts_name                = "${var.customershort_name}${var.environment}${substr("${identifier["name"]}", 0, 4)}"
        hostpool_type             = identifier["hostpool_type"]
        load_balancer_type        = identifier["load_balancer_type"]
        maximum_sessions_allowed  = identifier["maximum_sessions_allowed"]
        index                     = j
        number_vms                = identifier["number_vms"]
        application_list          = identifier["app_group_type"] == "RailApplications" ? identifier["application_list"] : [] #lookup(identifier, "application_list", [])
        avdprefix                 = "${var.customershort_name}${var.environment}${substr("${identifier["name"]}", 0, 4)}"
        ou_path                   = identifier["ou_path"]
        fslogix_fileshare_name    = identifier["fslogix_fileshare_name"]
        add_reader_group_name     = "group-avd-${local.region_name_standardize[key["location"] != "" ? key["location"] : var.principal_location]}-${identifier["name"]}-${var.environment}-reader"
        add_admin_group_name      = "group-avd-${local.region_name_standardize[key["location"] != "" ? key["location"] : var.principal_location]}-${identifier["name"]}-${var.environment}-admin"
        aad_operator_group_name   = "group-avd-${local.region_name_standardize[key["location"] != "" ? key["location"] : var.principal_location]}-${identifier["name"]}-${var.environment}-operator"
      }
    ]
  ])
}

locals {
  avd_operator_role_assignment_actions_definition = [
    "Microsoft.Authorization/*/read",
    "Microsoft.AzureStackHCI/operations/read",
    "Microsoft.AzureStackHCI/virtualMachineInstances/read",
    "Microsoft.AzureStackHCI/virtualMachineInstances/restart/action",
    "Microsoft.AzureStackHCI/virtualMachineInstances/start/action",
    "Microsoft.AzureStackHCI/virtualMachineInstances/stop/action",
    "Microsoft.Compute/virtualMachines/deallocate/action",
    "Microsoft.Compute/virtualMachines/instanceView/read",
    "Microsoft.Compute/virtualMachines/powerOff/action",
    "Microsoft.Compute/virtualMachines/read",
    "Microsoft.Compute/virtualMachines/restart/action",
    "Microsoft.Compute/virtualMachines/start/action",
    "Microsoft.ComputeSchedule/locations/virtualMachinesCancelOperations/action",
    "Microsoft.ComputeSchedule/locations/virtualMachinesExecuteDeallocate/action",
    "Microsoft.ComputeSchedule/locations/virtualMachinesExecuteHibernate/action",
    "Microsoft.ComputeSchedule/locations/virtualMachinesExecuteStart/action",
    "Microsoft.ComputeSchedule/locations/virtualMachinesGetOperationStatus/action",
    "Microsoft.ComputeSchedule/locations/virtualMachinesSubmitDeallocate/action",
    "Microsoft.ComputeSchedule/locations/virtualMachinesSubmitHibernate/action",
    "Microsoft.ComputeSchedule/locations/virtualMachinesSubmitStart/action",
    "Microsoft.ComputeSchedule/register/action",
    "Microsoft.DesktopVirtualization/hostpools/read",
    "Microsoft.DesktopVirtualization/hostpools/sessionhosts/read",
    "Microsoft.DesktopVirtualization/hostpools/sessionhosts/usersessions/delete",
    "Microsoft.DesktopVirtualization/hostpools/sessionhosts/usersessions/read",
    "Microsoft.DesktopVirtualization/hostpools/sessionhosts/usersessions/sendMessage/action",
    "Microsoft.DesktopVirtualization/hostpools/sessionhosts/write",
    "Microsoft.DesktopVirtualization/hostpools/write",
    "Microsoft.HybridCompute/locations/operationresults/read",
    "Microsoft.HybridCompute/locations/operationstatus/read",
    "Microsoft.HybridCompute/machines/read",
    "Microsoft.HybridCompute/operations/read",
    "Microsoft.Insights/alertRules/*",
    "Microsoft.Insights/eventtypes/values/read",
    "Microsoft.Resources/deployments/*",
    "Microsoft.Resources/subscriptions/resourceGroups/read",
    "Microsoft.DesktopVirtualization/hostpools/sessionhosts/usersessions/*",
    "Microsoft.Authorization/*/read",
    "Microsoft.Support/*",
    "Microsoft.DesktopVirtualization/workspaces/*",
    "Microsoft.DesktopVirtualization/applicationgroups/read",
    "Microsoft.DesktopVirtualization/hostpools/sessionhosts/*",
    "Microsoft.DesktopVirtualization/hostpools/*",
    "Microsoft.DesktopVirtualization/applicationgroups/*",
    "Microsoft.Resources/subscriptions/read",
    "Microsoft.DesktopVirtualization/appattachpackages/read",
    "Microsoft.DesktopVirtualization/appattachpackages/write",
    "Microsoft.DesktopVirtualization/appattachpackages/delete",
  ]
}

