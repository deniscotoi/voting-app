output "resource_group_name" {
  value = module.networking.resource_group_name
}

output "acr_login_server" {
  value = module.acr.login_server
}

output "aks_name" {
  value = module.aks.name
}

output "kube_config" {
  value     = module.aks.kube_config
  sensitive = true
}
