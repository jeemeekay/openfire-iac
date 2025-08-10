terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.48.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.51.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
  }
}

provider "azuread" {}

provider "azurerm" {
  features {}
}
