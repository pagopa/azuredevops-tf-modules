terraform {
  required_version = ">= 1.3.0"

  required_providers {
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = ">= 0.5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "<= 3.53.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 1.3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.7.0"
    }
  }
}
