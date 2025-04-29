variable "location" {
  default     = "eastus"
  description = "Location where the resource group and all the resources will be created"
}

variable "resource_group_name" {
  default     = ""
  description = "Resource Group name when necessary to not follow the current prefixes"
}

variable "avd_name" {
  default     = "desktop"
  description = "Naming purpose of the Azure Virtual Desktop, like desktop, application, etc"
}

variable "environment_name" {
  default     = "dev"
  description = "Environment name of the Azure Virtual Desktop, like prod, test, poc, etc"
}

variable "avd_index" {
  default     = "001"
  description = "Index of the Azure Virtual Desktop in case multiple AVDs with similar name exists"
}

variable "hostpool_name" {
  default     = ""
  description = "Host pool name when necessary to not follow the current prefixes"
}

variable "hostpool_type" {
  default     = "Pooled"
  description = "Host pool type. Allowed values are Pooled and Personal"
  validation {
    condition     = contains(["Pooled", "Personal"], var.hostpool_type)
    error_message = "Valid values are 'Pooled' or 'Personal'"
  }
}

variable "hostpool_load_balancer_type" {
  default     = "BreadthFirst"
  description = "Host pool load balancer type. Allowed values are BreadthFirst and DepthFirst"
  validation {
    condition     = contains(["BreadthFirst", "DepthFirst", "Persistent"], var.hostpool_load_balancer_type)
    error_message = "Possible values are BreadthFirst, DepthFirst and Persistent. DepthFirst load balancing distributes new user sessions to an available session host with the highest number of connections but has not reached its maximum session limit threshold. Persistent should be used if the host pool type is Personal"
  }
}

variable "personal_desktop_assignment_type" {
  default     = "Automatic"
  description = "Host pool load balancer type. Allowed values are BreadthFirst and DepthFirst"
  validation {
    condition     = contains(["Automatic", "Direct"], var.personal_desktop_assignment_type)
    error_message = "Automatic assignment – The service will select an available host and assign it to an user. Possible values are Automatic and Direct. Direct Assignment – Admin selects a specific host to assign to an user."
  }
}

variable "hostpool_validate_environment" {
  default     = false
  description = "Host pool validation environment. Allowed values are false and true"
  validation {
    condition     = contains([false, true], var.hostpool_validate_environment)
    error_message = "Valid values are 'false' or 'true'"
  }
}

variable "hostpool_start_vm_on_connect" {
  default     = false
  description = "Host pool validation start vm on connect. Allowed values are false and true"
  validation {
    condition     = contains([false, true], var.hostpool_start_vm_on_connect)
    error_message = "Valid values are 'false' or 'true'"
  }
}

variable "hostpool_maximum_sessions_allowed" {
  default     = 5
  description = "Host pool maximum sessions per host. Allowed values are false and true"
  validation {
    condition     = var.hostpool_maximum_sessions_allowed > 0
    error_message = "Valid values must be higgher than zero"
  }
}

variable "preferred_app_group_type" {
  default     = "Desktop"
  description = "Option to specify the preferred Application Group type for the Virtual Desktop Host Pool. Valid options are None, Desktop or RailApplications. Default is Desktop"
  validation {
    condition     = contains(["Desktop", "RailApplications"], var.preferred_app_group_type)
    error_message = "Valid values are 'Desktop' or 'RailApplications'"
  }
}

#Need to validate when the host type are Entra ID, then a new property must be added into it
variable "custom_rdp_properties" {
  default     = "enablecredsspsupport:i:1;videoplaybackmode:i:1;audiomode:i:0;devicestoredirect:s:*;drivestoredirect:s:*;redirectclipboard:i:1;redirectcomports:i:1;redirectprinters:i:1;redirectsmartcards:i:1;redirectwebauthn:i:1;usbdevicestoredirect:s:*;use multimon:i:1"
  description = "RDP Properties of the AVD"
}

variable "workspace_name" {
  default     = ""
  description = "Workspace name when necessary to not follow the current prefixes"
}

variable "virtual_network_resource_group_name" {
  type        = string
  description = "Resource group name where the virtual network is located"
}

variable "virtual_network_name" {
  type        = string
  description = "Virtual network name where the subnet is located"
}

variable "subnet_name" {
  type        = string
  description = "Subnet name"
}

#Must add a lenght limitation
variable "hostname_prefix" {
  type        = string
  description = "Host Name prefix"
  default     = "avd"
  validation {
    condition     = length(var.hostname_prefix) < 12
    error_message = "The host name value must have a length of at most 11"
  }
}

variable "local_admin_username" {
  type        = string
  description = "Local admin username"
}

variable "local_admin_password" {
  type        = string
  description = "Local admin password"
}

variable "domain_type" {
  type        = string
  description = "ADDS: Active Directory; AADDS: Azure Active Directory"
  default     = "ADDS"
  validation {
    condition     = contains(["ADDS", "AADDS"], var.domain_type)
    error_message = "Valid value is one of the following: ADDS, AADDS."
  }
}

variable "domain_name" {
  type = string
}

variable "ou_path" {
  type = string
}

variable "user_domain_join" {
  type = string
}

variable "password_domain_join" {
  type      = string
  sensitive = true
}

variable "number_of_hosts" {
  type        = number
  default     = 0
  description = "Specify the number of hosts that must be deployed"
}

variable "source_image_version_id" {
  type        = string
  default     = ""
  description = "VM Image version id available in the Azure Compute Gallery"
}

variable "data_collection_rule_id" {
  type        = string
  default     = ""
  description = "Data collection rule ID"
}

variable "user_group_name" {
  type    = list(string)
  default = []
}

variable "virtual_desktop_scaling_plan_time_zone" {
  type    = string
  default = "Eastern Standard Time"
}

variable "virtual_desktop_scaling_plan_schedule" {

}
variable "virtual_machine_size" {
  type = string
}

variable "log_analytics_workspace_id" {
  type    = string
  default = ""
}
