# Backend configuration for production environment
# Use with: terraform init -backend-config=environments/backend-prod.hcl

resource_group_name  = "rg-tfstate"
storage_account_name = "sttfstateYOURUNIQUE"
container_name       = "tfstate"
key                  = "voting-app-prod.terraform.tfstate"
