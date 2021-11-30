variable "AZURE_APP_ID" {
  description = "Azure app ID"
}

variable "AZURE_PASSWORD" {
  description = "Azure AZURE_PASSWORD"
}

variable "DEPLOYMENT_NAME" {
  description = "Name of deployment - used for the cluster name.  Example: rotate"
}

variable "VOTE_URL" {
  description = "Vote app url"
}

variable "RESULT_URL" {
  description = "Result app url"
}

locals {
  cluster_name = "compute-traffic-${var.DEPLOYMENT_NAME}"
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.66.0"
    }
    random = {
      source = "hashicorp/random"
      version = "3.1.0"
    }
  }
  required_version = ">= 0.14"
}

provider "azurerm" {
  features {}
}

provider "random" {
}

resource "random_password" "password" {
  length = 16
  special = true
}

resource "azurerm_resource_group" "traffic" {
  name     = "${local.cluster_name}-resources"
  location = "West US 2"
}

module "linuxservers" {
  source              = "Azure/compute/azurerm"
  resource_group_name = azurerm_resource_group.traffic.name
  vm_os_simple        = "UbuntuServer"
  public_ip_dns       = ["${local.cluster_name}vmips"]
  vnet_subnet_id      = module.network.vnet_subnets[0]
  enable_ssh_key      = false
  admin_password      = random_password.password.result

  depends_on = [azurerm_resource_group.traffic]

  custom_data = "${templatefile(
                  "../../scripts/loadgen-vm-setup-script.sh",
                  {
                    "VOTE_URL"=var.VOTE_URL,
                    "RESULT_URL"=var.RESULT_URL
                  }
                 )}"
}

module "network" {
  source              = "Azure/network/azurerm"
  resource_group_name = azurerm_resource_group.traffic.name
  subnet_prefixes     = ["10.0.1.0/24"]
  subnet_names        = ["subnet1"]

  depends_on = [azurerm_resource_group.traffic]
}

output "linux_vm_public_name" {
  value = module.linuxservers.public_ip_dns_name
}
