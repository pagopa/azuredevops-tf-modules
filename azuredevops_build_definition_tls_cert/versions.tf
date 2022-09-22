terraform {
  required_version = ">= 0.14.5"

  required_providers {
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = ">= 0.1.8"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.90.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.1.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.7.0"
    }
  }
}
