# Terraform Infrastructure as Code

This directory contains all Infrastructure-as-Code (IaC) for provisioning the Three-Tier Application deployment on Azure.

## Architecture Overview

The Terraform configuration provisions a complete Azure environment including:

- **Virtual Network (VNet)** with 3 subnets (AKS, Database, Monitoring)
- **Azure Kubernetes Service (AKS)** cluster with 3-5 worker nodes
- **Azure Container Registry (ACR)** for container image storage
- **PostgreSQL Flexible Server** managed database
- **Network Security Groups (NSGs)** for proper network isolation

## Directory Structure

```
terraform/
├── README.md                  # This file
├── main.tf                    # Root module - module composition
├── variables.tf              # Input variables with validation
├── outputs.tf                # Output values for external reference
│
├── modules/                  # Reusable Terraform modules
│   ├── networking/           # VNet, subnets, NSGs
│   │   ├── main.tf
│   │   └── variables.tf
│   ├── aks_cluster/          # Kubernetes cluster
│   │   ├── main.tf
│   │   └── variables.tf
│   ├── acr/                  # Container registry
│   │   ├── main.tf
│   │   └── variables.tf
│   └── db/                   # PostgreSQL database
│       ├── main.tf
│       └── variables.tf
│
└── environments/             # Environment-specific configs
    ├── README.md            # Detailed usage instructions
    ├── dev.tfvars           # Development variables
    └── prod.tfvars          # Production variables
```

## Module Descriptions

### Networking Module (`modules/networking/`)

Provisions cloud networking infrastructure with proper isolation:

- **Resources**:
  - Azure Resource Group
  - Virtual Network (VNet) with address space 10.0.0.0/16
  - AKS subnet (10.0.1.0/24) + NSG
  - Monitoring subnet (10.0.2.0/24) + NSG (for external agents)
  - Database subnet (10.0.3.0/24) + NSG with PostgreSQL delegation
  
- **Outputs**:
  - `resource_group_name` - Resource group for all resources
  - `vnet_id` - VNet ID
  - `aks_subnet_id` - AKS subnet
  - `monitoring_subnet_id` - Monitoring/external agent subnet
  - `db_subnet_id` - Database subnet

### AKS Module (`modules/aks_cluster/`)

Provisions managed Kubernetes cluster:

- **Resources**:
  - Azure Kubernetes Service (AKS) cluster
  - System node pool (configurable count/size)
  - Service principal with System-Assigned Identity
  - Network profile with Azure CNI plugin

- **Configuration**:
  - Cluster name format: `{project_name}-{environment}-aks`
  - Default nodes: 3 (dev), 5 (prod)
  - VM size: Standard_DS2_v2 (adjustable)
  - Kubernetes version: 1.29.0
  - Free tier SKU for cost optimization

- **Outputs**:
  - `name` - AKS cluster name
  - `kube_config` - Kubeconfig for kubectl access (sensitive)

### ACR Module (`modules/acr/`)

Provisions container image registry:

- **Resources**:
  - Azure Container Registry (ACR)
  - Standard tier for performance
  - Admin-disabled (use managed identities for access)

- **Configuration**:
  - Registry name format: `{project_name}{environment}acr`
  - SKU: Standard

- **Outputs**:
  - `login_server` - Registry DNS name
  - `id` - Registry resource ID

### Database Module (`modules/db/`)

Provisions managed PostgreSQL database:

- **Resources**:
  - PostgreSQL Flexible Server
  - Default database named "votingapp"
  - Automated backups (7-day retention)

- **Configuration**:
  - Server name format: `{project_name}-{environment}-pg`
  - SKU: B_Standard_B1ms
  - Storage: 32 GB
  - Version: PostgreSQL 16
  - HA: Disabled (can be enabled for prod)
  - VNet integration with delegated subnet

- **Outputs**:
  - `db_host` - Server FQDN
  - `db_name` - Database name
  - `db_username` - Admin username
  - `db_password` - Admin password (sensitive)

## Input Variables

All variables are defined in `variables.tf` with validation:

| Variable | Type | Required | Default | Notes |
|----------|------|----------|---------|-------|
| `project_name` | string | Yes | - | Resource prefix (3-24 chars recommended) |
| `environment` | string | Yes | - | Must be `dev` or `prod` |
| `location` | string | No | `westeurope` | Azure region |
| `kubernetes_node_count` | number | No | 3 | Minimum 3 nodes |
| `kubernetes_node_vm_size` | string | No | `Standard_DS2_v2` | Azure VM SKU |
| `kubernetes_version` | string | No | `1.29.0` | Kubernetes version |
| `db_admin_username` | string | No | `pgadmin` | PostgreSQL username (min 3 chars) |
| `db_admin_password` | string | Yes | - | PostgreSQL password (min 12 chars, sensitive) |

## Output Values

Root module exports critical infrastructure details for downstream usage:

```bash
# View all outputs
terraform output

# Get specific output
terraform output -raw kube_config > kubeconfig.yaml
terraform output acr_login_server
terraform output aks_name
```

## Quick Start

### 1. Initialize Terraform

```bash
# From terraform/ directory
terraform init -backend=false  # Skip backend initially to test locally
```

### 2. Validate Configuration

```bash
terraform validate
terraform fmt -recursive .  # Format code
```

### 3. Plan Infrastructure

```bash
# Development
terraform plan -var-file=environments/dev.tfvars -out=tfplan

# Production
terraform plan -var-file=environments/prod.tfvars -out=tfplan
```

### 4. Apply Configuration

```bash
terraform apply tfplan
```

See `environments/README.md` for detailed usage instructions.

## Best Practices Implemented

✅ **Modularization**: Reusable modules for networking, compute, storage, and database

✅ **Variable Validation**: Input validation with clear error messages

✅ **Parameterization**: No hardcoded values; all configurable via tfvars

✅ **Environment Isolation**: Separate tfvars for dev/prod with different resource sizing

✅ **Network Security**: NSGs with limited ingress/egress rules per layer

✅ **Naming Convention**: Consistent naming: `{project_name}-{environment}-{resource_type}`

✅ **Sensitive Data**: Database passwords marked as sensitive in outputs

✅ **Documentation**: Inline comments explaining complex configurations

✅ **State Management**: Remote backend in Azure Storage with locking

✅ **RBAC Ready**: AKS with system-assigned identity for secure credential management

## Networking Architecture

```
┌─────────────────────────────────────────────────────┐
│          Azure Virtual Network (10.0.0.0/16)        │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌──────────────────┐  ┌──────────────────┐       │
│  │ AKS Subnet       │  │ Monitoring       │       │
│  │ 10.0.1.0/24      │  │ 10.0.2.0/24      │       │
│  │                  │  │                  │       │
│  │ ┌──────────────┐ │  │ ┌──────────────┐ │       │
│  │ │ AKS Cluster  │ │  │ │  Monitoring  │ │       │
│  │ │ Nodes (3-5)  │ │  │ │  Agents (VMs)│ │       │
│  │ └──────────────┘ │  │ └──────────────┘ │       │
│  │                  │  │                  │       │
│  │ NSG: Allow LB    │  │ NSG: Allow VNet  │       │
│  │      Allow VNet  │  │      Allow Out   │       │
│  └──────────────────┘  └──────────────────┘       │
│         ⬇                                          │
│   Load Balancer (Public IP)                        │
│   API Gateway Ingress                              │
│                                                     │
│  ┌──────────────────────────────────────────┐    │
│  │        Database Subnet                    │    │
│  │        10.0.3.0/24                        │    │
│  │  ┌──────────────────────────────────┐    │    │
│  │  │  PostgreSQL Flexible Server      │    │    │
│  │  │  - Private endpoint              │    │    │
│  │  │  - Backup retention: 7 days      │    │    │
│  │  │  - Delegation: PostgreSQL        │    │    │
│  │  └──────────────────────────────────┘    │    │
│  │                                           │    │
│  │  NSG: Allow Port 5432 from VNet only      │    │
│  └──────────────────────────────────────────┘    │
│                                                     │
└─────────────────────────────────────────────────────┘
```

## State Management Configuration

The Terraform backend is configured to use Azure Storage for remote state:

```hcl
backend "azurerm" {
  resource_group_name  = "rg-tfstate"
  storage_account_name = "sttfstateYOURUNIQUE"  # Change this!
  container_name       = "tfstate"
  key                  = "infra.terraform.tfstate"
}
```

**Setup Instructions** in `environments/README.md#Bootstrap State Backend`

## Security Considerations

- **Database Password**: Use Azure Key Vault in production
- **Kubeconfig**: Marked as sensitive output, never logged
- **ACR Access**: Managed identity instead of admin credentials
- **Network Isolation**: Each tier has dedicated subnet with NSG rules
- **RBAC**: AKS with system-assigned identity for pod authentication

## Troubleshooting

### Terraform Plan Errors

```bash
# Validate syntax
terraform validate

# Check variable values
terraform console
terraform.vars.kubernetes_node_count

# Re-initialize (careful with state!)
terraform init -reconfigure
```

### Azure Resource Issues

```bash
# List created resources
az resource list --resource-group voting-app-dev-rg

# Check NSG rules
az network nsg rule list --resource-group voting-app-dev-rg --nsg-name voting-app-dev-aks-nsg
```

See full troubleshooting in `environments/README.md#Troubleshooting`

## Next Steps

1. ✅ **Provision Infrastructure**: Follow Quick Start above
2. 📦 **Deploy Helm Charts**: See `../helm-charts/` for application deployment
3. 📊 **Setup Monitoring**: See `../monitoring/` for Prometheus/Grafana/OTEL
4. 📝 **Document Architecture**: Update `../docs/ARCHITECTURE.md`

---

**Version**: 1.0  
**Terraform**: >= 1.6.0  
**Azure Provider**: ~> 4.0  
**Last Updated**: 2026-03-29
