resource "azurerm_resource_group" "fslogix_rg" {
  name     = local.fslogix_rg_name
  location = var.principal_location
}

resource "azurerm_storage_account" "fslogix_sta" {
  name                     = local.fslogix_sta_name
  resource_group_name      = azurerm_resource_group.fslogix_rg.name
  location                 = var.principal_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_share" "fslogix_share" {
  name                 = local.fslogix_storage_name
  storage_account_name = azurerm_storage_account.fslogix_sta.name
  quota                = 50
}
