output "hostpool" {
  value = var.hostpool_type == "Personal" ? azurerm_virtual_desktop_host_pool.avd_personal[0] : azurerm_virtual_desktop_host_pool.avd_pooled[0]
}

