# Development Environment Configuration
# This file is safe to commit - use Azure Key Vault or .tfvars.local for secrets

project_name              = "voting-app"
environment               = "dev"
location                  = "westeurope"

# Kubernetes Configuration
kubernetes_node_count     = 3
kubernetes_node_vm_size   = "Standard_DS2_v2"
kubernetes_version        = "1.29.0"

# Database Configuration (use Azure Key Vault in production)
db_admin_username = "pgadmin"
db_admin_password = "CHANGE_ME_STRONG_PASSWORD" # use Azure key vault variable or something similar