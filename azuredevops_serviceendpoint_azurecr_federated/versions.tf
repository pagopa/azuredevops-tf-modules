terraform {
  required_version = ">= 1.3.0"

  required_providers {
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = ">= 1.1"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.107"
    }
  }
}
