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

variable "kubernetes_node_count" {
  type        = number
  description = "AKS node count"
  default     = 3
}

variable "kubernetes_node_vm_size" {
  type        = string
  description = "AKS node VM size"
  default     = "Standard_DS2_v2"
}

variable "kubernetes_version" {
  type        = string
  description = "AKS version"
  default     = "1.29.0"
}
