# Terraform env var files

Use `dev.tfvars` for development and `prod.tfvars` for production.

Apply with:

- `terraform apply -var-file=terraform/environments/dev.tfvars`
- `terraform apply -var-file=terraform/environments/prod.tfvars`

Plan with:

- `terraform plan -var-file=terraform/environments/prod.tfvars`
