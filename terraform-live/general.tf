resource "azurerm_resource_group" "rg_general" {
  name     = local.rg_general_name
  location = var.principal_location
}

resource "azurerm_key_vault" "kv_general" {
  name                = local.kv_general_name
  resource_group_name = azurerm_resource_group.rg_general.name
  location            = azurerm_resource_group.rg_general.location
  tenant_id           = data.azurerm_client_config.current.tenant_id

  soft_delete_retention_days = local.kv_general_soft_delete_retention_days
  purge_protection_enabled   = local.kv_general_purge_protection_enabled

  sku_name = local.kv_general_sku_name

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Get",
    ]

    storage_permissions = [
      "Get",
    ]
  }
}


