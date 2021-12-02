terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.66.0"
    }
    ssh = {
      source  = "loafoe/ssh"
      version = "1.0.1"
    }
  }
  required_version = ">= 0.14"
}

provider "azurerm" {
  features {}
}

resource "tls_private_key" "keypair" {
  algorithm = "RSA"
}

## Add key directly to instance
resource "azuread_application" "main" {
  for_each     = toset(["leia", "luke", "han"])
  display_name = "tf-principal-${each.value}"
}

# Create Service Principal associated with the Azure AD App
resource "azuread_service_principal" "main" {
  for_each                     = azuread_application.main
  application_id               = each.value.application_id
  app_role_assignment_required = false
}

# Create service principal password
resource "azuread_application_password" "main" {
  for_each              = azuread_application.main
  application_object_id = each.value.id
}

data "azurerm_subscription" "primary" {}

resource "azurerm_role_assignment" "main" {
  for_each             = azuread_service_principal.main
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Contributor"
  principal_id         = each.value.id
  depends_on = [
    azuread_service_principal.main
  ]
}

locals {
  creds = merge({
    for k, v in azuread_application.main : k => tomap({
      client_id : v.application_id
      client_secret : azuread_application_password.main[k].value
      tenant_id : data.azurerm_subscription.primary.tenant_id
      sub_id : data.azurerm_subscription.primary.subscription_id
      app_name : v.display_name
    })
  })
}

# Create VM
#
resource "azurerm_resource_group" "activity-vm-rg" {
  name     = "activity-vm-rg"
  location = "centralus"
}

resource "azurerm_virtual_network" "activity-network" {
  name                = "activity-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.activity-vm-rg.location
  resource_group_name = azurerm_resource_group.activity-vm-rg.name
}

resource "azurerm_subnet" "activty-subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.activity-vm-rg.name
  virtual_network_name = azurerm_virtual_network.activity-network.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "activity-vm-nic" {
  name                = "activity-vm-nic"
  location            = azurerm_resource_group.activity-vm-rg.location
  resource_group_name = azurerm_resource_group.activity-vm-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.activty-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.activity-vm-pub-ip.id
  }
}

resource "azurerm_linux_virtual_machine" "activity-vm" {
  name                = "activty-vm"
  resource_group_name = azurerm_resource_group.activity-vm-rg.name
  location            = azurerm_resource_group.activity-vm-rg.location
  size                = "Standard_DS1_v2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.activity-vm-nic.id
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = tls_private_key.keypair.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
}

resource "azurerm_public_ip" "activity-vm-pub-ip" {
  name                = "activity-vm-pub-ip"
  resource_group_name = azurerm_resource_group.activity-vm-rg.name
  location            = azurerm_resource_group.activity-vm-rg.location
  allocation_method   = "Dynamic"

  tags = {
    environment = "activity-vm"
  }
}

resource "azurerm_network_security_group" "activity-vm-sg" {
  name                = "activity-vm-sg"
  location            = azurerm_resource_group.activity-vm-rg.location
  resource_group_name = azurerm_resource_group.activity-vm-rg.name

  security_rule {
    name                       = "ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production"
  }
}

resource "azurerm_network_interface_security_group_association" "activity-vm-nic-assoc" {
  network_interface_id      = azurerm_network_interface.activity-vm-nic.id
  network_security_group_id = azurerm_network_security_group.activity-vm-sg.id
}

resource "time_sleep" "wait_for_vm" {
  depends_on      = [azurerm_linux_virtual_machine.activity-vm]
  create_duration = "120s"
}


resource "ssh_resource" "adminuser_tf_dir" {
  host        = azurerm_public_ip.activity-vm-pub-ip.ip_address
  user        = "adminuser"
  host_user   = "adminuser"
  private_key = tls_private_key.keypair.private_key_pem
  commands    = ["mkdir -p /home/adminuser/tf || exit 0"]
  depends_on = [
    azurerm_linux_virtual_machine.activity-vm,
    time_sleep.wait_for_vm,
    azurerm_public_ip.activity-vm-pub-ip,
  ]
}

resource "ssh_resource" "run_file" {
  host        = azurerm_public_ip.activity-vm-pub-ip.ip_address
  host_user   = "adminuser"
  user        = "adminuser"
  private_key = tls_private_key.keypair.private_key_pem
  depends_on  = [ssh_resource.adminuser_tf_dir]

  file {
    destination = "/home/adminuser/tf/main.tf"
    content     = file("${path.module}/files/main.tf.demo.source")
    permissions = "0660"
  }

  file {
    destination = "/home/adminuser/tf/azure_run.sh"
    content = templatefile(
      "${path.module}/files/run.tpl",
      {
        apps = local.creds
      }
    )
    permissions = "0700"
  }

  file {
    destination = "/home/adminuser/setup.sh"
    content     = file("${path.module}/files/setup.sh")
    permissions = "0700"
  }

  commands = ["/home/adminuser/setup.sh"]
}
