# Random string for unique naming
resource "random_string" "suffix" {
  count   = var.create_ml_workspace ? var.live_workspace_count : 0
  length  = 6
  special = false
  upper   = false
}

# Application Insights (ML Workspace 필수 구성요소)
resource "azurerm_application_insights" "ml_insights" {
  count               = var.create_ml_workspace ? var.live_workspace_count : 0
  name                = format("%02dinsights%s", count.index + 1, var.user_suffix)
  location            = azurerm_resource_group.rg[count.index].location
  resource_group_name = azurerm_resource_group.rg[count.index].name
  application_type    = "web"
}

# Key Vault (ML Workspace 필수 구성요소)
resource "azurerm_key_vault" "ml_kv" {
  count                      = var.create_ml_workspace ? var.live_workspace_count : 0
  name                       = format("%02dkv%s%s", count.index + 1, var.user_suffix, random_string.suffix[count.index].result)
  location                   = azurerm_resource_group.rg[count.index].location
  resource_group_name        = azurerm_resource_group.rg[count.index].name
  enabled_for_disk_encryption = true
  tenant_id                  = var.tenant_id
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  sku_name                   = "standard"
}

# Storage Account (ML Workspace 필수 구성요소)
resource "azurerm_storage_account" "ml_storage" {
  count                    = var.create_ml_workspace ? var.live_workspace_count : 0
  name                     = format("%02dstorage%s%s", count.index + 1, lower(var.user_suffix), random_string.suffix[count.index].result)
  resource_group_name      = azurerm_resource_group.rg[count.index].name
  location                 = azurerm_resource_group.rg[count.index].location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Container Registry (ML Workspace 필수 구성요소)
resource "azurerm_container_registry" "ml_acr" {
  count               = var.create_ml_workspace ? var.live_workspace_count : 0
  name                = format("%02dacr%s%s", count.index + 1, lower(var.user_suffix), random_string.suffix[count.index].result)
  resource_group_name = azurerm_resource_group.rg[count.index].name
  location            = azurerm_resource_group.rg[count.index].location
  sku                 = "Basic"
  admin_enabled       = true
}

# ML Workspace 생성
resource "azurerm_machine_learning_workspace" "ml_workspace" {
  count                   = var.create_ml_workspace ? var.live_workspace_count : 0
  name                    = format("%02dmlworkspace%s", count.index + 1, var.user_suffix)
  location                = azurerm_resource_group.rg[count.index].location
  resource_group_name     = azurerm_resource_group.rg[count.index].name
  application_insights_id = azurerm_application_insights.ml_insights[count.index].id
  key_vault_id            = azurerm_key_vault.ml_kv[count.index].id
  storage_account_id      = azurerm_storage_account.ml_storage[count.index].id
  container_registry_id   = azurerm_container_registry.ml_acr[count.index].id

  identity {
    type = "SystemAssigned"
  }

  depends_on = [
    azurerm_application_insights.ml_insights,
    azurerm_key_vault.ml_kv,
    azurerm_storage_account.ml_storage,
    azurerm_container_registry.ml_acr
  ]
}

# Key Vault Access Policy for ML Workspace
resource "azurerm_key_vault_access_policy" "ml_workspace_policy" {
  count        = var.create_ml_workspace ? var.live_workspace_count : 0
  key_vault_id = azurerm_key_vault.ml_kv[count.index].id
  tenant_id    = var.tenant_id
  object_id    = azurerm_machine_learning_workspace.ml_workspace[count.index].identity[0].principal_id

  key_permissions = [
    "Get", "List", "Create", "Delete", "Update", "Recover", "Purge"
  ]

  secret_permissions = [
    "Get", "List", "Set", "Delete", "Recover", "Purge"
  ]

  certificate_permissions = [
    "Get", "List", "Create", "Delete", "Update", "Recover", "Purge"
  ]

  depends_on = [azurerm_machine_learning_workspace.ml_workspace]
}

# Key Vault Access Policy for Users
resource "azurerm_key_vault_access_policy" "user_kv_policy" {
  count        = var.create_ml_workspace ? var.live_workspace_count : 0
  key_vault_id = azurerm_key_vault.ml_kv[count.index].id
  tenant_id    = var.tenant_id
  object_id    = azuread_user.rag_users[count.index].object_id

  secret_permissions = [
    "Get", "List", "Set"
  ]

  depends_on = [azuread_user.rag_users, azurerm_key_vault.ml_kv]
}

# ML Compute Instance 생성 (Standard_E4ds_v4, 2시간 idle shutdown)
resource "azapi_resource" "ml_compute_instance" {
  count     = var.create_ml_workspace ? var.live_workspace_count : 0
  type      = "Microsoft.MachineLearningServices/workspaces/computes@2023-04-01"
  name      = format("%02dcomputeinstance%s", count.index + 1, var.user_suffix)
  parent_id = azurerm_machine_learning_workspace.ml_workspace[count.index].id

  body = jsonencode({
    properties = {
      computeType = "ComputeInstance"
      properties = {
        vmSize = var.ml_vm_size
        idleTimeBeforeShutdown = var.ml_idle_shutdown
        personalComputeInstanceSettings = {
          assignedUser = {
            objectId = azuread_user.rag_users[count.index].object_id
            tenantId = var.tenant_id
          }
        }
      }
    }
  })

  depends_on = [azurerm_machine_learning_workspace.ml_workspace]
}

resource "null_resource" "start_ml_computes" {
  count = var.create_ml_workspace && var.start_computes ? var.live_workspace_count : 0

  provisioner "local-exec" {
    command = <<-EOT
      az ml compute start \
        --name "${format("%02dcomputeinstance%s", count.index + 1, var.user_suffix)}" \
        --workspace-name "${azurerm_machine_learning_workspace.ml_workspace[count.index].name}" \
        --resource-group "${azurerm_resource_group.rg[count.index].name}" \
        --no-wait
      
      echo "Started compute: ${format("%02dcomputeinstance%s", count.index + 1, var.user_suffix)}"
    EOT
  }

  depends_on = [azapi_resource.ml_compute_instance]
}

