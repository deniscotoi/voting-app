resource "azurerm_resource_group" "rg" {
  name     = "${var.project_name}-${var.environment}-rg"
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.project_name}-${var.environment}-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

# ===== AKS Subnet =====
resource "azurerm_subnet" "aks" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "aks_nsg" {
  name                = "${var.project_name}-${var.environment}-aks-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ingress {
    name                   = "AllowLoadBalancer"
    priority               = 100
    direction              = "Inbound"
    access                 = "Allow"
    protocol               = "*"
    source_port_range      = "*"
    destination_port_range = "*"
    source_address_prefix  = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  ingress {
    name                   = "AllowVNetInbound"
    priority               = 110
    direction              = "Inbound"
    access                 = "Allow"
    protocol               = "*"
    source_port_range      = "*"
    destination_port_range = "*"
    source_address_prefix  = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  egress {
    name                   = "AllowAllOutbound"
    priority               = 100
    direction              = "Outbound"
    access                 = "Allow"
    protocol               = "*"
    source_port_range      = "*"
    destination_port_range = "*"
    source_address_prefix  = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "aks_nsg_assoc" {
  subnet_id                 = azurerm_subnet.aks.id
  network_security_group_id = azurerm_network_security_group.aks_nsg.id
}

# ===== Monitoring Subnet (for external monitoring agents) =====
resource "azurerm_subnet" "monitoring" {
  name                 = "monitoring-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "monitoring_nsg" {
  name                = "${var.project_name}-${var.environment}-monitoring-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ingress {
    name                   = "AllowVNetInbound"
    priority               = 100
    direction              = "Inbound"
    access                 = "Allow"
    protocol               = "*"
    source_port_range      = "*"
    destination_port_range = "*"
    source_address_prefix  = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  egress {
    name                   = "AllowAllOutbound"
    priority               = 100
    direction              = "Outbound"
    access                 = "Allow"
    protocol               = "*"
    source_port_range      = "*"
    destination_port_range = "*"
    source_address_prefix  = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "monitoring_nsg_assoc" {
  subnet_id                 = azurerm_subnet.monitoring.id
  network_security_group_id = azurerm_network_security_group.monitoring_nsg.id
}

# ===== Database Subnet =====
resource "azurerm_subnet" "db" {
  name                 = "db-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.3.0/24"]

  delegations {
    name = "db-delegation"

    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_network_security_group" "db_nsg" {
  name                = "${var.project_name}-${var.environment}-db-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ingress {
    name                   = "AllowPostgresFromVNet"
    priority               = 100
    direction              = "Inbound"
    access                 = "Allow"
    protocol               = "tcp"
    source_port_range      = "*"
    destination_port_range = "5432"
    source_address_prefix  = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  egress {
    name                   = "AllowAllOutbound"
    priority               = 100
    direction              = "Outbound"
    access                 = "Allow"
    protocol               = "*"
    source_port_range      = "*"
    destination_port_range = "*"
    source_address_prefix  = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "db_nsg_assoc" {
  subnet_id                 = azurerm_subnet.db.id
  network_security_group_id = azurerm_network_security_group.db_nsg.id
}

# ===== Outputs =====
output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "aks_subnet_id" {
  value = azurerm_subnet.aks.id
}

output "monitoring_subnet_id" {
  value = azurerm_subnet.monitoring.id
}

output "db_subnet_id" {
  value = azurerm_subnet.db.id
}
