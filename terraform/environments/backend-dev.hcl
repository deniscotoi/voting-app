# Backend configuration for development environment
# Use with: terraform init -backend-config=environments/backend-dev.hcl

resource_group_name  = "rg-tfstate"
storage_account_name = "sttfstateYOURUNIQUE"
container_name       = "tfstate"
key                  = "voting-app-dev.terraform.tfstate"
