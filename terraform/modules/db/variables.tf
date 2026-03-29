variable "project_name"        { type = string }
variable "environment"         { type = string }
variable "location"            { type = string }
variable "resource_group_name" { type = string }
variable "vnet_id"             { type = string }
variable "db_subnet_id"        { type = string }

variable "db_admin_username" {
  type        = string
  description = "DB admin username"
}

variable "db_admin_password" {
  type        = string
  description = "DB admin password"
  sensitive   = true
}

variable "db_name" {
  type        = string
  description = "Application database name"
  default     = "votingapp"
}
