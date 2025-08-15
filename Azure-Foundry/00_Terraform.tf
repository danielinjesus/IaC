terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "= 3.108.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.48.0" # 최신 안정 버전을 확인하여 사용하세요.
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
# 프로코드 : 기여자 권한, Blob Storage 데이터 Contributor
#전현준 강사님의 Pro-coder 강의용 테라폼 코드입니다.
# 구독의 소유자여야만 AI Foundry 리소스를 생성가능합니다.