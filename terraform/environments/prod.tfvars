# Production Environment Configuration
# IMPORTANT: Use Azure Key Vault for sensitive variables
# Never commit actual passwords to version control

project_name              = "voting-app"
environment               = "prod"
location                  = "westeurope"

# Kubernetes Configuration
kubernetes_node_count     = 5
kubernetes_node_vm_size   = "Standard_DS2_v2"
kubernetes_version        = "1.29.0"

# Database Configuration (MUST use Azure Key Vault in production)
db_admin_username = "pgadmin"
db_admin_password = "CHANGE_ME_STRONG_PASSWORD" # use Azure key vault variable or something similar