terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47.0" # 최신 안정 버전을 확인하여 사용하세요.
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 1.5"
    }
  }
  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
provider "azuread" {
}
provider "azapi" {
}

resource "azuread_user" "rag_users" {
  count               = var.user_count
  user_principal_name = format("%02d_user_%s%s", count.index + 1, var.user_suffix, var.tenant_email)
  display_name        = format("%02d_user_%s", count.index + 1, var.user_suffix)
  password            = var.initial_pwd
}
resource "azurerm_resource_group" "rg" { # 01_RG부터 35_RG까지 생성
  count    = var.user_count
  name     = format("%02d_RG_%s", count.index + 1, var.user_suffix)
  location = var.location
}
resource "azurerm_role_assignment" "user_rg_roles" {
  for_each = {
    for pair in setproduct(range(var.user_count), var.roles) :
    # 고유한 for_each 키 생성 (예: "user00_role_Contributor")
    # 역할 이름에 공백이 있을 수 있으므로 "_"로 대체합니다.
    format("user%02d_role_%s", pair[0], replace(pair[1], " ", "_")) => {
      user_idx = pair[0] # 사용자 및 리소스 그룹 인덱스
      role     = pair[1] # 할당할 역할 이름
    }
  }
  scope                = azurerm_resource_group.rg[each.value.user_idx].id
  role_definition_name = each.value.role
  principal_id         = azuread_user.rag_users[each.value.user_idx].object_id
  depends_on           = [azuread_user.rag_users, azurerm_resource_group.rg]
}