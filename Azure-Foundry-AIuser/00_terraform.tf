terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 1.5"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"  # 최신 버전으로 업그레이드
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Provider 블록들
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

provider "azuread" {
}

provider "azapi" {
}