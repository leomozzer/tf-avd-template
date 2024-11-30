terraform {
  backend "azurerm" {
    resource_group_name  = "rg-lsoavdstac"
    storage_account_name = "lsoavdstac"
    container_name       = "states"
    key                  = "prod.tfstate"
  }
}
