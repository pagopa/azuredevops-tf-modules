terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "~> 1.8"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.114.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}
