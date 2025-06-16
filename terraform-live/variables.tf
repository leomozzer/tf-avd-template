variable "principal_location" {
  type        = string
  description = "Location were most of the commom resources will be deployed"
  default     = "eastus"
}

# variable "customershort_name" {
#   type        = string
#   description = "Name of the customer short, must have 3 letters at maximum"
# }

variable "environment" {
  type        = string
  description = "prod, dev, test"
}

variable "avd_subscription_id" {
  type = string
}

#Must add a lenght limitation
variable "hostname_prefix" {
  type        = string
  description = "Host Name prefix"
}

variable "number_of_hosts" {
  type        = number
  default     = 1
  description = "Specify the number of hosts that must be deployed"
}

variable "key_vm_credentials_name" {
  type = string
}

variable "key_vm_credentials_resource_group_name" {
  type = string
}

variable "vm_source_image_id" {
  type    = string
  default = ""
}

variable "domain_name" {
  type = string
}

variable "domain_type" {
  type        = string
  description = "AD: Active Directory; AAD: Azure Active Directory"
}

variable "key_vault_name" {
  type = string
}

variable "key_vault_resource_group" {
  type = string
}

variable "rg_vnet_name" {
  type    = string
  default = ""
}

variable "vnet_name" {
  type    = string
  default = ""
}

variable "snet_name" {
  type    = string
  default = ""
}

variable "ou_path" {
  type = string
}

# variable "initiative_definitions" {
#   type    = any
#   default = []
# }

# variable "policy_definitions" {
#   type = any
# }

# variable "management_group_id" {
#   type = string
# }

