variable "project_name" {
  type        = string
  description = "Project prefix for all resources"
}

variable "location" {
  type        = string
  description = "Azure region"
  default     = "westeurope"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, prod)"

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be either 'dev' or 'prod'"
  }
}

# ===== Kubernetes Configuration =====
variable "kubernetes_node_count" {
  type        = number
  description = "AKS node count (minimum 3 for production)"
  default     = 3

  validation {
    condition     = var.kubernetes_node_count >= 3
    error_message = "kubernetes_node_count must be at least 3"
  }
}

variable "kubernetes_node_vm_size" {
  type        = string
  description = "AKS node VM size (Azure SKU)"
  default     = "Standard_DS2_v2"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version for AKS cluster"
  default     = "1.29.0"
}

# ===== Database Configuration =====
variable "db_admin_username" {
  type        = string
  description = "PostgreSQL admin username"
  default     = "pgadmin"

  validation {
    condition     = length(var.db_admin_username) >= 3
    error_message = "db_admin_username must be at least 3 characters"
  }
}

variable "db_admin_password" {
  type        = string
  description = "PostgreSQL admin password (use strong password, consider using Azure Key Vault)"
  sensitive   = true

  validation {
    condition     = length(var.db_admin_password) >= 12
    error_message = "db_admin_password must be at least 12 characters (security requirement)"
  }
}
