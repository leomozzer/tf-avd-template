variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "environment" {
  type = string
}

variable "avdprefix" {
  type = string
}

variable "admin_group_avd_name" {
  type = string
}

variable "admin_reader_avd_name" {
  type = string
}

variable "operator_group_avd_name" {
  type = string
}

variable "hostpool_name" {
  type = string
}

variable "hostpool_type" {
  type = string
}

variable "hostpool_load_balancer_type" {
  type = string
}

variable "hostpool_validate_environment" {
  type    = bool
  default = false
}

variable "hostpool_start_vm_on_connect" {
  type    = bool
  default = true
}

variable "hostpool_maximum_sessions_allowed" {
  type = number
}

variable "preferred_app_group_type" {
  type = string
}

variable "custom_rdp_properties" {
  type    = string
  default = "enablecredsspsupport:i:1;videoplaybackmode:i:1;audiomode:i:0;devicestoredirect:s:*;drivestoredirect:s:*;redirectclipboard:i:1;redirectcomports:i:1;redirectprinters:i:1;redirectsmartcards:i:1;redirectwebauthn:i:1;usbdevicestoredirect:s:*;use multimon:i:1"
}

variable "workspace_name" {
  type = string
}

variable "application_list" {
  type    = list(any)
  default = []
}

variable "number_vms" {
  type    = number
  default = 0
}

variable "spoke_resource_group_name" {
  type = string
}

variable "spoke_vnet_name" {
  type = string
}

variable "avd_vnet_name" {
  type = string
}

variable "vm_size" {
  type    = string
  default = "Standard_D8as_v4"
}

variable "vm_admin_username" {
  type = string
}

variable "vm_admin_password" {
  type      = string
  sensitive = true
}

variable "password_domain_join" {
  type      = string
  sensitive = true
}

variable "os_disk_caching" {
  type    = string
  default = "ReadWrite"
}

variable "os_disk_storage_account_type" {
  type    = string
  default = "Standard_LRS"
  validation {
    condition     = contains(["Standard_LRS", "Premium_LRS"], var.os_disk_storage_account_type)
    error_message = "Valid value is one of the following: Standard_LRS, Premium_LRS."
  }
}

variable "source_image_reference_publisher" {
  type    = string
  default = "MicrosoftWindowsDesktop"
  validation {
    condition     = contains(["MicrosoftWindowsDesktop", "MicrosoftWindowsServer"], var.source_image_reference_publisher)
    error_message = "Valid value is one of the following: MicrosoftWindowsDesktop, MicrosoftWindowsServer."
  }
}

variable "source_image_reference_offer" {
  type    = string
  default = "Windows-11"
  validation {
    condition     = contains(["Windows-10", "Windows-11", "Office-365"], var.source_image_reference_offer)
    error_message = "Valid value is one of the following: Windows-10, Windows-11."
  }
}

variable "source_image_reference_sku" {
  type    = string
  default = "win11-23h2-avd-m365"
  validation {
    condition     = contains(["win11-23h2-avd-m365", "win11-23h2-avd"], var.source_image_reference_sku)
    error_message = "Valid value is one of the following: win11-23h2-avd-m365"
  }
}

variable "vm_source_image_id" {
  type    = string
  default = ""
}

variable "domain_type" {
  type        = string
  description = "AD: Active Directory; AAD: Azure Active Directory"
  default     = "AD"
  validation {
    condition     = contains(["AD", "AAD"], var.domain_type)
    error_message = "Valid value is one of the following: AD, AAD."
  }
}

variable "domain_name" {
  type = string
}

variable "ou_path" {
  type = string
}

variable "user_domainjoin" {
  type = string
}

variable "vm_tags" {
  type    = object({})
  default = {}
}

variable "vm_extension_timezone_name" {
  type    = string
  default = ""
}

variable "vm_extension_fslogix_sta_name" {
  type    = string
  default = ""
}

variable "vm_extension_fslogix_fileshare_name" {
  type    = string
  default = ""
}

variable "vm_extension_fslogix_directory_name" {
  type    = string
  default = ""
}
variable "data_collection_rule_id" {
  type = string
}

variable "enable_scaling_plan" {
  type    = bool
  default = false
}
