resource "azurerm_resource_group" "rg_search" {
  name     = var.ai_search_rg
  location = var.location
}
resource "azurerm_search_service" "shared_ai_search" {
  count               = var.create_shared_search ? 1 : 0
  name                = "shared-ai-search"
  sku                 = "standard"
  location            = var.location
  resource_group_name = var.ai_search_rg
}

variable "ai_search_rg" { default = "ai_search_RG" }
variable "create_shared_search" { default = false }