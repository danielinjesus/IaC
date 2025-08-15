# # Random string for unique naming
# resource "random_string" "suffix" {
#   count   = var.create_ml_workspace ? var.live_workspace_count : 0
#   length  = 6
#   special = false
#   upper   = false
# }
# # [변경됨] 사용자별 Log Analytics Workspace 생성
# # 공유 리소스를 제거하고, 각 사용자의 RG에 개별적으로 생성합니다.
# resource "azurerm_log_analytics_workspace" "ml_la" {
#   count               = var.create_ml_workspace ? var.live_workspace_count : 0
#   name                = format("la%02d%s", count.index + 1, var.user_suffix)
#   location            = azurerm_resource_group.rg[count.index].location
#   resource_group_name = azurerm_resource_group.rg[count.index].name
#   sku                 = "PerGB2018"
#   retention_in_days   = 30
# }
# # [변경됨] Application Insights 수정
# # workspace_id가 각 사용자의 Log Analytics Workspace를 가리키도록 수정합니다.
# resource "azurerm_application_insights" "ml_insights" {
#   count               = var.create_ml_workspace ? var.live_workspace_count : 0
#   name                = format("%02dinsights%s", count.index + 1, var.user_suffix)
#   location            = azurerm_resource_group.rg[count.index].location
#   resource_group_name = azurerm_resource_group.rg[count.index].name
#   application_type    = "web"
#   workspace_id        = azurerm_log_analytics_workspace.ml_la[count.index].id # <-- 이 부분이 변경되었습니다.
# }
# # Key Vault (ML Workspace 필수 구성요소)
# resource "azurerm_key_vault" "ml_kv" {
#   count                       = var.create_ml_workspace ? var.live_workspace_count : 0
#   name                        = format("kv%02d%s%s", count.index + 1, var.user_suffix, random_string.suffix[count.index].result)
#   location                    = azurerm_resource_group.rg[count.index].location
#   resource_group_name         = azurerm_resource_group.rg[count.index].name
#   enabled_for_disk_encryption = true
#   tenant_id                   = var.tenant_id
#   soft_delete_retention_days  = 7
#   purge_protection_enabled    = false
#   sku_name                    = "standard"
# }
# # Key Vault Access Policy for Users
# resource "azurerm_key_vault_access_policy" "user_kv_policy" {
#   count        = var.create_ml_workspace ? var.live_workspace_count : 0
#   key_vault_id = azurerm_key_vault.ml_kv[count.index].id
#   tenant_id    = var.tenant_id
#   object_id    = azuread_user.rag_users[count.index].object_id
#   secret_permissions = [
#     "Get", "List", "Set"
#   ]
#   depends_on = [azuread_user.rag_users, azurerm_key_vault.ml_kv]
# }
# # Storage Account (ML Workspace 필수 구성요소)
# resource "azurerm_storage_account" "ml_storage" {
#   count                    = var.create_ml_workspace ? var.live_workspace_count : 0
#   name                     = format("%02dstorage%s%s", count.index + 1, lower(var.user_suffix), random_string.suffix[count.index].result)
#   resource_group_name      = azurerm_resource_group.rg[count.index].name
#   location                 = azurerm_resource_group.rg[count.index].location
#   account_tier             = "Standard"
#   account_replication_type = "LRS"
# }
# # Container Registry (ML Workspace 필수 구성요소)
# resource "azurerm_container_registry" "ml_acr" {
#   count               = var.create_ml_workspace ? var.live_workspace_count : 0
#   name                = format("%02dcontainer%s%s", count.index + 1, lower(var.user_suffix), random_string.suffix[count.index].result)
#   resource_group_name = azurerm_resource_group.rg[count.index].name
#   location            = azurerm_resource_group.rg[count.index].location
#   sku                 = "Basic"
#   admin_enabled       = true
# }
# # ML Workspace 생성
# resource "azurerm_machine_learning_workspace" "ml_workspace" {
#   count                   = var.create_ml_workspace ? var.live_workspace_count : 0
#   name                    = format("%02dmlworkspace%s", count.index + 1, var.user_suffix)
#   location                = azurerm_resource_group.rg[count.index].location
#   resource_group_name     = azurerm_resource_group.rg[count.index].name
#   application_insights_id = azurerm_application_insights.ml_insights[count.index].id
#   key_vault_id            = azurerm_key_vault.ml_kv[count.index].id
#   storage_account_id      = azurerm_storage_account.ml_storage[count.index].id
#   container_registry_id   = azurerm_container_registry.ml_acr[count.index].id
#   public_network_access_enabled = true
#   identity {
#     type = "SystemAssigned"
#   }
#   depends_on = [
#     azurerm_application_insights.ml_insights,
#     azurerm_key_vault.ml_kv,
#     azurerm_storage_account.ml_storage,
#     azurerm_container_registry.ml_acr,
#     # 새로 생성된 Log Analytics Workspace에 대한 의존성 추가
#     azurerm_log_analytics_workspace.ml_la
#   ]
# }
# # ML Compute Instance 생성 (Standard_E4ds_v4, 2시간 idle shutdown)
# resource "azapi_resource" "ml_compute_instance" {
#   count     = var.create_ml_workspace ? var.live_workspace_count : 0
#   type      = "Microsoft.MachineLearningServices/workspaces/computes@2023-04-01"
#   name      = format("compute%02d%s", count.index + 1, var.user_suffix)
#   parent_id = azurerm_machine_learning_workspace.ml_workspace[count.index].id
#   # 스키마 검증 비활성화
#   schema_validation_enabled = false
#   body = jsonencode({
#     location = azurerm_machine_learning_workspace.ml_workspace[count.index].location
#     properties = {
#       computeType = "ComputeInstance"
#       properties = {
#         vmSize                 = var.ml_vm_size
#         idleTimeBeforeShutdown = var.ml_idle_shutdown
#         personalComputeInstanceSettings = {
#           assignedUser = {
#             objectId = azuread_user.rag_users[count.index].object_id
#             tenantId = var.tenant_id
#           }
#         }
#       }
#     }
#   })
#   depends_on = [azurerm_machine_learning_workspace.ml_workspace]
# }