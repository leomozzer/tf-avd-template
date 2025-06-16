# terraform {
#   required_providers {
#     azurerm = {
#       version = "4.27.0"
#     }
#   }
# }

provider "azurerm" {
  subscription_id = var.avd_subscription_id
  features {

  }
}
