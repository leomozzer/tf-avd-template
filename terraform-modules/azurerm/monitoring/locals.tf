locals {
  resource_group_name = "rg-${var.log_name != "" ? var.log_name : "vdimonitor-${var.location_prefix}-01"}"
  name                = "log-${var.log_name != "" ? var.log_name : "vdimonitor-${var.location_prefix}-01"}"
  dcr_name            = "microsoft-avdi-${var.location}"
}
