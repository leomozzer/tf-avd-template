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

variable "vnet_avd_definition" {
  type = list(object({
    subscription_id = string
    identifier      = optional(string)
    vnets = optional(list(object({
      location      = string
      address_space = list(string)
      subnets = optional(list(object({
        address_prefix = string
      })))
    })))
  }))
  default = [{
    subscription_id = "",
    identifier      = "",
    spokes = [{
      location      = "",
      address_space = [],
      subnets       = []
    }]
  }]
}

variable "data_vnet_hub" {
  type = object({
    name                = string
    resource_group_name = string
  })
}
