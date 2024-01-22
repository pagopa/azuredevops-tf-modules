terraform {
  required_version = ">= 1.3.0"

  required_providers {
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = ">= 0.10.0, <= 0.12.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "<= 3.71.0"
    }
  }
}

