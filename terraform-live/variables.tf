variable "principal_location" {
  type        = string
  description = "Location were most of the commom resources will be deployed"
  default     = "eastus"
}

variable "customershort_name" {
  type        = string
  description = "Name of the customer short, must have 3 letters at maximum"
}

variable "environment" {
  type        = string
  description = "prod, dev, test"
}

variable "avd_subscription_id" {
  type = string
}

variable "avd_definition" {
  type = list(object({
    subscription_id = string
    location        = optional(string)
    identifier = optional(list(object({
      name                     = string
      app_group_type           = string
      hostpool_type            = string
      load_balancer_type       = string
      number_vms               = number
      maximum_sessions_allowed = number
      ou_path                  = string
      fslogix_fileshare_name   = optional(string)
      application_list = optional(list(object({
        name                         = string
        friendly_name                = string
        description                  = string
        path                         = string
        command_line_argument_policy = string
        command_line_arguments       = string
        show_in_portal               = bool
        icon_path                    = string
        icon_index                   = number
      })))
    })))
  }))
  default = [{
    subscription_id = "",
    "location"      = "eastus"
    identifier = [{
      "name"                   = "desktop"
      "app_group_type"         = "Desktop"
      "hostpool_type"          = "Pooled"
      "load_balancer_type"     = "BreadthFirst"
      "number_vms"             = 1
      maximum_sessions_allowed = 5
      ou_path                  = ""
    }]
  }]
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

variable "custom_rdp_properties" {
  type    = string
  default = ""
}

variable "vm_tags" {
  type    = object({})
  default = {}
}

variable "domain_name" {
  type = string
}

variable "vm_admin_username" {
  type    = string
  default = "local_admin"
}

variable "vm_admin_password" {
  type    = string
  default = "ChangeME!142536#"
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

variable "fslogix_sta_name" {
  type    = string
  default = ""
}

variable "fslogix_fileshare_name" {
  type    = string
  default = ""
}

variable "fslogix_directory" {
  type    = string
  default = ""
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

