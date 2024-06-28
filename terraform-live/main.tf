resource "azurerm_resource_group" "rg_avd_general" {
  for_each = {
    for index, identifier in local.default_avd_definition : index => identifier
  }
  name     = "${each.value.resource_group_name}-${each.value.number_id}"
  location = each.value.location
}

resource "azurerm_storage_account" "fslogix_sta" {
  for_each = {
    for index, identifier in local.default_avd_definition : index => identifier
  }
  name                     = "${each.value.sta_fslogix_name}${each.value.number_id}"
  resource_group_name      = azurerm_resource_group.rg_avd_general[each.value.index].name
  location                 = each.value.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_share" "fslogix_share" {
  for_each = {
    for index, identifier in local.default_avd_definition : index => identifier
  }
  name                 = "${each.value.fslogix_storage_name}${each.value.number_id}"
  storage_account_name = azurerm_storage_account.fslogix_sta[each.value.index].name
  quota                = 50
}
