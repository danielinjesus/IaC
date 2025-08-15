# Azure AI Foundry Resource 생성
resource "azurerm_cognitive_account" "foundry_service" {
  count               = var.create_ml_workspace && var.enable_azure_openai ? var.live_workspace_count : 0
  name                = format("%02dfoundryservice%s%s", count.index + 1, lower(var.user_suffix), random_string.suffix[count.index].result)
  location            = azurerm_resource_group.rg[count.index].location
  resource_group_name = azurerm_resource_group.rg[count.index].name
  kind                = "AIServices" # OpenAI → AIServices로 변경
  sku_name            = var.azure_openai_sku_name
  tags = {
    environment = "rag_project"
    user_index  = format("%02d", count.index + 1)
  }
  depends_on = [azurerm_resource_group.rg, random_string.suffix]
}
# GPT 모델 배포
resource "azurerm_cognitive_deployment" "gpt_model_deployment" {
  count                 = var.create_ml_workspace && var.enable_azure_openai ? var.live_workspace_count : 0
  name                  = format("%02dgptdeploy%s", count.index + 1, var.user_suffix)
  cognitive_account_id  = azurerm_cognitive_account.openai_service[count.index].id
  resource_group_name   = azurerm_resource_group.rg[count.index].name # Cognitive Deployment는 RG 이름도 필요
  model {
    format = "OpenAI"
    name   = var.azure_openai_gpt_model_name
    version = var.azure_openai_model_version # 일부 모델은 버전 지정 필수
  }
  scale {
    type = "Standard" # 또는 "Manual" 등, 모델 및 SKU에 따라 다름
  }
  depends_on = [azurerm_cognitive_account.openai_service]
}
# Embedding 모델 배포
resource "azurerm_cognitive_deployment" "embedding_model_deployment" {
  count                 = var.create_ml_workspace && var.enable_azure_openai ? var.live_workspace_count : 0
  name                  = format("%02dembeddeploy%s", count.index + 1, var.user_suffix)
  cognitive_account_id  = azurerm_cognitive_account.openai_service[count.index].id
  resource_group_name   = azurerm_resource_group.rg[count.index].name # Cognitive Deployment는 RG 이름도 필요
  model {
    format = "OpenAI"
    name   = var.azure_openai_embedding_model_name
    version = "2" # text-embedding-ada-002의 일반적인 버전은 "2" 입니다. text-embedding-3-small의 경우 확인 필요
  }
  scale {
    type = "Standard"
  }
  depends_on = [azurerm_cognitive_account.openai_service]
}
