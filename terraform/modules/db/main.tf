resource "azurerm_postgresql_flexible_server" "db" {
  name                   = "${var.project_name}-${var.environment}-pg"
  resource_group_name    = var.resource_group_name
  location               = var.location
  sku_name               = "B_Standard_B1ms"
  storage_mb             = 32768
  version                = "16"
  administrator_login    = var.db_admin_username
  administrator_password = var.db_admin_password

  high_availability {
    mode = "Disabled"
  }

  network {
    delegated_subnet_id = var.db_subnet_id
  }

  backup {
    backup_retention_days = 7
  }
}

resource "azurerm_postgresql_flexible_server_database" "app" {
  name      = var.db_name
  server_id = azurerm_postgresql_flexible_server.db.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

output "db_host" {
  value = azurerm_postgresql_flexible_server.db.fqdn
}

output "db_name" {
  value = azurerm_postgresql_flexible_server_database.app.name
}

output "db_username" {
  value = "${var.db_admin_username}@${azurerm_postgresql_flexible_server.db.name}"
}

output "db_password" {
  value     = var.db_admin_password
  sensitive = true
}
