variable "AZURE_APP_ID" {
  description = "Azure app ID"
}

variable "AZURE_PASSWORD" {
  description = "Azure AZURE_PASSWORD"
}

variable "DEPLOYMENT_NAME" {
  description = "Name of deployment - used for the cluster name.  Example: rotate"
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.66.0"
    }
  }

  required_version = ">= 0.14"
}

resource "random_pet" "prefix" {}

locals {
  cluster_name = "aks-demo-${var.DEPLOYMENT_NAME}"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "default" {
  name     = "${local.cluster_name}-rg"
  location = "West US 2"

  tags = {
    environment = "Demo"
  }
}

resource "azurerm_kubernetes_cluster" "default" {
  name                = "${local.cluster_name}-aks"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  dns_prefix          = "${local.cluster_name}-k8s"

  default_node_pool {
    name            = "default"
    node_count      = 2
    vm_size         = "Standard_D2_v2"
    os_disk_size_gb = 30
  }

  service_principal {
    client_id     = var.AZURE_APP_ID
    client_secret = var.AZURE_PASSWORD
  }

  role_based_access_control {
    enabled = true
  }

  tags = {
    environment = "demo"
  }
}

