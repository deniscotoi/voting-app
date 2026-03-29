# Terraform Environment Configuration

This directory contains environment-specific variable files for Terraform deployments.

## Files

- **dev.tfvars** - Development environment configuration
- **prod.tfvars** - Production environment configuration

## Usage

### Prerequisites

1. **Azure Subscription**: Ensure you have access to an Azure subscription
2. **Terraform CLI**: Version >= 1.6.0 installed
3. **Azure CLI**: Logged in with `az login`
4. **State Backend**: Bootstrap the remote state backend (see below)

### Bootstrap State Backend

Before running any Terraform commands, you must create the Azure Storage Account for remote state:

```bash
# Create resource group and storage account for Terraform state
az group create --name rg-tfstate --location westeurope

az storage account create \
  --name sttfstateYOURUNIQUE \
  --resource-group rg-tfstate \
  --location westeurope

az storage container create \
  --name tfstate \
  --account-name sttfstateYOURUNIQUE
```

Then update `main.tf` backend configuration with your storage account name.

### Initialize Terraform

```bash
cd ../
terraform init -backend-config="storage_account_name=sttfstateYOURUNIQUE"
```

### Plan Deployment

**Development:**
```bash
terraform plan -var-file=environments/dev.tfvars -out=tfplan-dev
```

**Production:**
```bash
terraform plan -var-file=environments/prod.tfvars -out=tfplan-prod
```

### Apply Configuration

**Development:**
```bash
terraform apply tfplan-dev
```

**Production:**
```bash
terraform apply tfplan-prod
```

## Environment Variables

All variables are defined in `../variables.tf`. Key variables:

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `project_name` | Yes | - | Project prefix for all resources |
| `environment` | Yes | - | Environment name: `dev` or `prod` |
| `location` | No | `westeurope` | Azure region |
| `kubernetes_node_count` | No | 3 | AKS worker node count (min 3) |
| `kubernetes_node_vm_size` | No | `Standard_DS2_v2` | VM instance type for AKS nodes |
| `kubernetes_version` | No | `1.29.0` | Kubernetes version |
| `db_admin_username` | No | `pgadmin` | PostgreSQL admin username |
| `db_admin_password` | Yes | - | PostgreSQL admin password |

## Secrets Management

**IMPORTANT**: Never commit actual passwords to version control.

### For Development
- Use placeholder in `dev.tfvars`: `CHANGE_ME_STRONG_PASSWORD`
- Override with environment variable or `-var` flag:
  ```bash
  terraform plan -var-file=environments/dev.tfvars \
    -var="db_admin_password=your_secure_password"
  ```

### For Production
- **MUST** use Azure Key Vault:
  ```bash
  az keyvault secret show --vault-name your-kv --name db-password --query value
  ```
- Reference via environment variable:
  ```bash
  export TF_VAR_db_admin_password=$(az keyvault secret show --vault-name your-kv \
    --name db-password --query value)
  terraform plan -var-file=environments/prod.tfvars
  ```

## Outputs

After successful apply, retrieve outputs:

```bash
terraform output resource_group_name
terraform output aks_name
terraform output acr_login_server
terraform output db_host
terraform output kube_config
```

## State Management

- **State Location**: Azure Storage Account (`rg-tfstate` resource group)
- **Isolation**: Each environment has a separate state file
- **Locking**: Azure automatically locks state during operations
- **Backup**: Auto-configured with 7-day retention

## Troubleshooting

### "backend already configured"
```bash
terraform init -reconfigure
```

### Pod can't reach database
1. Check database subnet delegation: `az network vnet subnet show --resource-group <rg-name> --vnet-name <vnet-name> --name db-subnet`
2. Verify network security groups allow traffic on port 5432
3. Ensure database firewall rules allow Azure services

### ACR pull errors
1. Verify AKS has proper RBAC to ACR: `az role assignment list --assignee <aks-identity-id>`
2. Check ACR admin_enabled setting

## Cleanup

**WARNING**: This will destroy all infrastructure.

```bash
terraform destroy -var-file=environments/prod.tfvars
```

