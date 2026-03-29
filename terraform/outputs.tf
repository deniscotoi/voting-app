# Azure Infrastructure Outputs

output "resource_group_name" {
  value       = module.networking.resource_group_name
  description = "Azure Resource Group name"
}

output "vnet_id" {
  value       = module.networking.vnet_id
  description = "Virtual Network ID"
}

output "aks_subnet_id" {
  value       = module.networking.aks_subnet_id
  description = "AKS subnet ID"
}

output "db_subnet_id" {
  value       = module.networking.db_subnet_id
  description = "Database subnet ID"
}

output "monitoring_subnet_id" {
  value       = module.networking.monitoring_subnet_id
  description = "Monitoring subnet ID for external agents"
}

# Container Registry Outputs

output "acr_login_server" {
  value       = module.acr.login_server
  description = "ACR login server address"
}

output "acr_id" {
  value       = module.acr.id
  description = "Container Registry resource ID"
}

# Kubernetes Cluster Outputs

output "aks_name" {
  value       = module.aks.name
  description = "AKS cluster name"
}

output "kube_config" {
  value       = module.aks.kube_config
  sensitive   = true
  description = "Kubernetes cluster config (kubeconfig)"
}

# Database Outputs

output "db_host" {
  value       = module.db.db_host
  description = "PostgreSQL server FQDN"
}

output "db_name" {
  value       = module.db.db_name
  description = "Application database name"
}

output "db_username" {
  value       = module.db.db_username
  description = "Database admin username"
}

output "db_password" {
  value       = module.db.db_password
  sensitive   = true
  description = "Database admin password"
}
