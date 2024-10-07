data "azurerm_image" "frontend" {
  name                = var.frontend_image.name
  resource_group_name = var.frontend_image.resource_group_name
}

resource "azurerm_network_interface" "frontend" {
  count = var.az_count
  name                = "nic-${var.application_name}-${var.environment_name}-frontend${count.index}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.frontend.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "frontend" {
  count = var.az_count
  name                = "vm-${var.application_name}-${var.environment_name}-frontend${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = "Standard_F2"
  admin_username      = var.admin_username
  zone                = count.index + 1
  network_interface_ids = [
    azurerm_network_interface.frontend[count.index].id
  ]
  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.ssh.public_key_openssh
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_id = data.azurerm_image.frontend.id
  user_data       = data.cloudinit_config.frontend.rendered
}