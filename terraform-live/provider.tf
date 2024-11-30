provider "azurerm" {
  skip_provider_registration = true
  subscription_id            = var.avd_subscription_id
  features {

  }
}

