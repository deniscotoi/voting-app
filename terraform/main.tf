terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-tfstate" # to be renamed after manual creation or bootstrap script
    storage_account_name = "sttfstateYOURUNIQUE" # to be renamed after manual creation or bootstrap script
    container_name       = "tfstate"
    key                  = "infra.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

module "networking" {
  source       = "./modules/networking"
  project_name = var.project_name
  environment  = var.environment
  location     = var.location
}

module "acr" {
  source             = "./modules/acr"
  project_name       = var.project_name
  environment        = var.environment
  location           = var.location
  resource_group_name = module.networking.resource_group_name
}

module "aks" {
  source             = "./modules/aks_cluster"
  project_name       = var.project_name
  environment        = var.environment
  location           = var.location
  resource_group_name = module.networking.resource_group_name
  aks_subnet_id      = module.networking.aks_subnet_id
  node_count         = var.kubernetes_node_count
  node_vm_size       = var.kubernetes_node_vm_size
}

module "db" {
  source              = "./modules/db"
  project_name        = var.project_name
  environment         = var.environment
  location            = var.location
  resource_group_name = module.networking.resource_group_name
  vnet_id             = module.networking.vnet_id
  db_subnet_id        = module.networking.db_subnet_id

  db_admin_username = var.db_admin_username
  db_admin_password = var.db_admin_password
  db_name           = "votingapp"
}
