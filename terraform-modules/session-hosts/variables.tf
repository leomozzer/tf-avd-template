variable "location" {
  default     = "eastus"
  description = "Location where the resource group and all the resources will be created"
}

variable "resource_group_name" {
  description = "Resource group name where the host will be created"
}

variable "number_of_hosts" {
  type        = number
  default     = 1
  description = "Specify the number of hosts that must be deployed"
}

#Must add a lenght limitation
variable "hostname_prefix" {
  type        = string
  description = "Host Name prefix"
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

variable "source_image_version_id" {
  type        = string
  default     = ""
  description = "VM Image version id available in the Azure Compute Gallery"
}

variable "virtual_machine_size" {
  type        = string
  default     = "Standard_D8as_v4"
  description = "Virtual machine size"
  #Required to add validation?
}

variable "local_admin_username" {
  type        = string
  description = "Local admin username"
}

variable "local_admin_password" {
  type        = string
  description = "Local admin password"
}

variable "os_disk_caching" {
  type        = string
  default     = "ReadWrite"
  description = "The Type of Caching which should be used for the Internal OS Disk."
  validation {
    condition     = contains(["None", "ReadOnly ", "ReadWrite"], var.os_disk_caching)
    error_message = "Possible values are None, ReadOnly and ReadWrite"
  }
}

variable "os_disk_storage_account_type" {
  type        = string
  default     = "Standard_LRS"
  description = "The Type of Storage Account which should back this the Internal OS Disk"
  validation {
    condition     = contains(["Standard_LRS", "StandardSSD_LRS", "Premium_LRS", "StandardSSD_ZRS", "Premium_ZRS"], var.os_disk_storage_account_type)
    error_message = "Possible values are Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS and Premium_ZRS"
  }
}

variable "virtual_machine_timezone_name" {
  type        = string
  default     = "UTC"
  description = "Specifies the Time Zone which should be used by the Virtual Machine"
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
  type        = string
  default     = "win11-23h2-avd"
  description = "SKU of the virtual machine. For more details check the Microsoft Documentation"
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

variable "virtual_desktop_host_pool_name" {
  type        = string
  description = "Azure Virtual Desktop Host Pool name"
}

variable "virtual_desktop_host_pool_registration_token" {
  type        = string
  description = "Azure Virtual Desktop Host Pool registration token"
}
