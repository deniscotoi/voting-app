# Voting Application - Production Infrastructure & Deployment

Complete production-ready implementation of a three-tier voting application on Azure Kubernetes Service (AKS) with comprehensive monitoring, API gateway, and operational documentation.

## Quick Deployment

```bash
# 1. Clone and navigate
cd terraform/

# 2. Initialize infrastructure (Azure Cloud)
terraform init -backend-config=environments/backend-prod.hcl
terraform plan -var-file=environments/prod.tfvars
terraform apply -var-file=environments/prod.tfvars

# 3. Get credentials
terraform output -json kube_config | jq -r . > kubeconfig.yaml
export KUBECONFIG=$(pwd)/kubeconfig.yaml

# 4. Deploy application stack
./scripts/deploy.sh

# 5. Access application
# Frontend: https://voting-app.example.com
# API: https://api.voting-app.example.com
# Monitoring: kubectl port-forward -n monitoring svc/grafana 3000:80
```

## Documentation

### Infrastructure & Architecture
- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** - System design, cloud infrastructure, Kubernetes architecture, data flows, disaster recovery
- **[CONFIG.md](docs/CONFIG.md)** - Configuration reference for Terraform, Kubernetes, Helm, monitoring, database, API, and secrets

### Deployment & Operations
- **[DEPLOYMENT.md](docs/DEPLOYMENT.md)** - Step-by-step deployment guide with all commands and troubleshooting
- **[OPERATIONS.md](docs/OPERATIONS.md)** - Daily operations, scaling, disaster recovery, troubleshooting, incident response runbooks
- **[MONITORING.md](docs/MONITORING.md)** - Monitoring stack overview, key metrics, dashboards, alert rules, SLO/SLI definitions, PromQL queries

### Code Reference
- **[terraform/README.md](terraform/README.md)** - Terraform module architecture, variables, outputs, deployment
- **[helm-charts/README.md](helm-charts/README.md)** - Helm charts structure, quick start, customization, deployment

## Project Structure

```
voting-app/
├── terraform/                          # Infrastructure as Code
│   ├── main.tf                        # Module orchestration
│   ├── variables.tf                   # Input variables with validation
│   ├── outputs.tf                     # Resource group, AKS, ACR, DB outputs
│   ├── README.md                      # Terraform documentation
│   ├── modules/
│   │   ├── networking/                # VNet, subnets, NSGs
│   │   ├── aks_cluster/               # AKS cluster with RBAC
│   │   ├── acr/                       # Azure Container Registry
│   │   └── db/                        # PostgreSQL Flexible Server
│   └── environments/
│       ├── dev.tfvars                 # Dev: 3 nodes
│       ├── prod.tfvars                # Prod: 5 nodes
│       ├── backend-dev.hcl            # Dev state isolation
│       ├── backend-prod.hcl           # Prod state isolation
│       └── README.md                  # Environment setup guide
│
├── helm-charts/                       # Kubernetes deployment
│   ├── common-lib/                    # Reusable deployment, service, HPA templates
│   ├── services/
│   │   ├── frontend/                  # React app, 3 replicas, port 3000
│   │   ├── api/                       # REST API, 3-10 replicas, port 8080
│   │   └── worker/                    # Async processor, 1-5 replicas
│   ├── ingress-controller/            # NGINX Ingress, TLS, security headers
│   └── README.md                      # Helm deployment guide
│
├── monitoring/                        # Observability stack
│   ├── prometheus/                    # Metrics collection (15d retention, 50GB)
│   │   ├── values.yaml
│   │   ├── prometheus.yml             # Scrape configs
│   │   └── alerts.yml                 # 20+ alert rules
│   ├── grafana/                       # Metrics visualization
│   │   └── dashboards/                # Pre-configured dashboards
│   ├── otel-collector/                # Trace aggregation
│   ├── blackbox/                      # External probing
│   └── README.md                      # Monitoring setup
│
├── scripts/
│   └── deploy.sh                      # Automated 10-step deployment (300+ lines)
│
├── docs/
│   ├── ARCHITECTURE.md                # System design & infrastructure
│   ├── DEPLOYMENT.md                  # Step-by-step deployment guide
│   ├── OPERATIONS.md                  # Runbooks & troubleshooting
│   ├── MONITORING.md                  # Monitoring implementation & SLO/SLI
│   └── CONFIG.md                      # Configuration reference
│
└── README.md                          # This file
```

## Technology Stack

| Component | Version | Purpose |
|-----------|---------|---------|
| **Cloud** | Azure | AKS, ACR, VNet, NSGs, PostgreSQL Flexible Server |
| **Kubernetes** | 1.29.0 | Container orchestration |
| **Helm** | 3.x | Application deployment & configuration |
| **Monitoring** | - | Prometheus (metrics), Grafana (dashboards), AlertManager |
| **Tracing** | OpenTelemetry | Distributed tracing & correlation |
| **API Gateway** | NGINX | Ingress controller, TLS, routing, security headers |
| **Database** | PostgreSQL 16 | Persistent data, 7-day backups, VNet integration |
| **Infrastructure** | Terraform 1.6+ | IaC for reproducible deployments |

## Features

### ✅ Infrastructure as Code
- Modularized Terraform for AKS, networking, registry, database
- Separate dev/prod environments with isolated state
- Network segmentation (AKS, Database, Monitoring subnets)
- Comprehensive NSG rules for security
- Service delegates for database VNet integration

### ✅ Monitoring & Observability
- Prometheus for metrics collection (15-day retention)
- Grafana with pre-configured dashboards
- 20+ alert rules for operational visibility
- OpenTelemetry Collector for trace aggregation
- Blackbox Exporter for external probing (API, DB, DNS)
- SLO/SLI definitions (99.9% availability)

### ✅ Production API Gateway
- NGINX Ingress Controller with 2 replicas
- TLS/SSL with automatic Let's Encrypt certificates
- Path-based routing (frontend, API, worker services)
- Security headers (HSTS, X-Frame-Options, CORS)
- Rate limiting (100 RPS default)
- Request/response logging and metrics

### ✅ Three-Tier Application Deployment
- Frontend (React) - 2-5 replicas (CPU autoscaling)
- API (REST) - 3-10 replicas (CPU + RPS autoscaling)
- Worker (Background) - 1-5 replicas (CPU autoscaling)
- Common Helm library reduces chart duplication
- Health checks (liveness, readiness)
- Resource limits and requests
- Pod disruption budgets for high availability

### ✅ Database Management
- PostgreSQL 16 on Azure managed service
- Automatic backups (7-day retention)
- VNet integration for network isolation
- Performance monitoring
- Connection pooling support

### ✅ Comprehensive Documentation
- Architecture diagrams (system, cloud, Kubernetes, monitoring)
- Configuration reference for all components
- Step-by-step deployment guide
- Operational runbooks and troubleshooting
- Daily operations, scaling, disaster recovery procedures
- Incident response playbooks

## Getting Started

### Prerequisites
```bash
# Required tools
- terraform 1.6+
- kubectl 1.29+
- helm 3.x
- az CLI 2.50+
- curl, jq, bash

# Azure Account
- Subscription with quota for:
  - AKS cluster (5 nodes)
  - PostgreSQL Flexible Server
  - Azure Container Registry
  - Virtual Networks
```

### Deployment Steps

**1. Infrastructure Setup**
```bash
cd terraform
terraform init -backend-config=environments/backend-prod.hcl
terraform plan -var-file=environments/prod.tfvars
terraform apply -var-file=environments/prod.tfvars
```

**2. Get Kubeconfig**
```bash
terraform output -json kube_config | jq -r . > kubeconfig.yaml
export KUBECONFIG=$(pwd)/kubeconfig.yaml
kubectl cluster-info
```

**3. Deploy Stack**
```bash
cd ..
./scripts/deploy.sh
# Automated deployment of:
# - Monitoring (Prometheus, Grafana, OTEL)
# - API Gateway (NGINX Ingress)
# - Applications (Frontend, API, Worker)
# - Database schema initialization
```

**4. Verify Deployment**
```bash
# Check all services running
kubectl get pods -n default
kubectl get pods -n monitoring
kubectl get svc

# Get LoadBalancer IP
kubectl get svc ingress-nginx -n ingress-nginx

# Test API endpoint
curl https://api.voting-app.example.com/api/v1/health
```

**5. Access Services**
- **Frontend**: https://voting-app.example.com
- **API**: https://api.voting-app.example.com
- **Grafana**: `kubectl port-forward -n monitoring svc/grafana 3000:80` → http://localhost:3000
- **Prometheus**: `kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090` → http://localhost:9090

## Configuration

> **Complete configuration reference**: See [CONFIG.md](docs/CONFIG.md)

### Environment Variables

**Development (`terraform/environments/dev.tfvars`)**:
```hcl
environment               = "dev"
kubernetes_node_count     = 3      # Minimum nodes
kubernetes_node_vm_size   = "Standard_DS2_v2"
```

**Production (`terraform/environments/prod.tfvars`)**:
```hcl
environment               = "prod"
kubernetes_node_count     = 5      # Higher for redundancy
kubernetes_node_vm_size   = "Standard_DS2_v2"
```

### Helm Values Customization

Edit service chart values before deployment:
```bash
# Frontend
helm-charts/services/frontend/values.yaml  # image, replicas, resources

# API
helm-charts/services/api/values.yaml       # database config, scaling

# Worker
helm-charts/services/worker/values.yaml    # queue config, intervals
```

## Monitoring & Alerts

### Alert Rules

Pre-configured alerts for:
- **Availability**: HTTP errors >5% (critical)
- **Performance**: Latency p95 >500ms (warning)
- **Infrastructure**: Node memory/disk pressure
- **Database**: Connection exhaustion, slow queries
- **SLO**: Availability <99.9% for 5min
- **Pods**: CrashLoopBackOff, OOMKilled, PVC space

### Dashboards

Access Grafana to view:
- **Application Overview** - Request rate, errors, latency by service
- **API Gateway** - HTTP codes, upstream latency, rate limit hits
- **Infrastructure** - Node CPU/memory, networking, storage
- **Database** - Connections, transactions, query performance
- **Availability** - Monthly uptime %, error budget tracking

## Operations

> **Complete operational guide**: See [OPERATIONS.md](docs/OPERATIONS.md)

### Daily Checks
```bash
# Check cluster health
kubectl cluster-info && kubectl get nodes

# Check pod status
kubectl get pods -n default && kubectl get pods -n monitoring

# View alerts
curl http://alertmanager:9093/api/v1/alerts

# Check resource usage
kubectl top nodes && kubectl top pods
```

### Common Tasks

**Scale Services**:
```bash
# Manual scaling
kubectl scale deployment voting-app-api --replicas=7

# Adjust autoscaling
helm upgrade api helm-charts/services/api \
    --set autoscaling.maxReplicas=15
```

**Update Application**:
```bash
# Build and push image
az acr build --registry $ACR_NAME --image voting-app-api:v1.0.1 .

# Update deployment
helm upgrade api helm-charts/services/api \
    --set image.tag=v1.0.1
```

**Rollback Deployment**:
```bash
helm history api
helm rollback api 2  # Rollback to previous version
```

**View Logs**:
```bash
kubectl logs -f deployment/voting-app-api
kubectl logs -f deployment/voting-app-worker
```

### Disaster Recovery

**Database Failure**:
```bash
# Check DB health
psql -h <db-host> -U pgadmin -d votingapp -c "SELECT 1"

# Restore from backup
terraform destroy -target azurerm_postgresql_flexible_server.db
terraform apply -target azurerm_postgresql_flexible_server.db
```

**Node Failure**:
```bash
# Kubernetes auto-recovers pods
# Monitor redeployment
kubectl get pods -w

# If persistent, drain & replace
kubectl drain <node> --ignore-daemonsets
```

**Full Cluster Recovery**:
```bash
# Recreate from IaC
terraform destroy
terraform apply -var-file=environments/prod.tfvars

# Reapply Helm charts
./scripts/deploy.sh
```

## Troubleshooting

> **Complete troubleshooting guide**: See [OPERATIONS.md](docs/OPERATIONS.md)

### Pod Issues
- **CrashLooping**: Check logs, memory limits, database connectivity
- **Pending**: Verify resources available, check node constraints
- **ImagePullBackOff**: Verify ACR credentials, image tag

### Database Issues
- **Connection Timeout**: Check DB is running, verify NSG rules, credentials
- **Slow Queries**: Monitor Prometheus dashboard, add indexes
- **Disk Space**: Check PVC size, archive old data

### Monitoring Issues
- **No Metrics**: Verify scrape configs, pod annotations, service discovery
- **Alert Not Firing**: Check alert rule syntax, check rule matches

### Network Issues
- **Services Not Reachable**: Check Ingress, NSG, LoadBalancer IP
- **TLS Errors**: Verify certificate, check cert-manager logs

## Support & Documentation

| Item | Location |
|------|----------|
| Architecture & Design | [ARCHITECTURE.md](docs/ARCHITECTURE.md) |
| Step-by-Step Deployment | [DEPLOYMENT.md](docs/DEPLOYMENT.md) |
| Operational Procedures | [OPERATIONS.md](docs/OPERATIONS.md) |
| Configuration Reference | [CONFIG.md](docs/CONFIG.md) |
| Monitoring Setup | [MONITORING.md](docs/MONITORING.md) |
| Terraform Modules | [terraform/README.md](terraform/README.md) |
| Helm Charts | [helm-charts/README.md](helm-charts/README.md) |

## Environment Requirements

### Azure Subscription Quotas
- Min 5 vCPUs for AKS nodes
- 500GB storage for databases/backups
- 5 public IPs (ingress, node scale)

### Local Development
```bash
# Check tool versions
kubectl version --client
helm version
terraform -version
az --version

# Authenticate to Azure
az login
az account set --subscription <subscription-id>
```

## Security Considerations

### Network Security
- VNet isolation (AKS, Database, Monitoring subnets)
- NSG rules restrict traffic by application (allow LB→AKS, allow AKS→DB)
- Service delegates prevent direct DB access

### Pod Security
- Non-root users
- Read-only filesystems
- Network policies (coming soon)

### Secrets Management
- Kubernetes Secrets for runtime credentials
- Azure Key Vault support (via CSI driver)
- Certificate management via cert-manager

### Access Control
- RBAC for Kubernetes API
- Service accounts with minimal permissions
- Audit logging for compliance

## Cost Optimization

### Recommendations
- Dev environment: 3-node cluster, Standard_B2s VMs
- Prod environment: 5-node cluster, Standard_DS2_v2 VMs
- Database: Standard tier with pause capability for dev
- Storage: Delete old metrics (configure Prometheus retention)
- Networking: Consolidate NSGs, use service delegates

### Estimated Monthly Cost (Prod)
- AKS: ~200-300 USD (5 nodes × Standard_DS2_v2)
- PostgreSQL: ~100-150 USD (32GB Standard tier)
- ACR: ~50 USD (Standard tier)
- Storage: ~20-30 USD (50GB Prometheus + backups)
- **Total**: ~370-530 USD/month

## Roadmap

### Completed ✅
- Infrastructure provisioning (Terraform)
- Production monitoring stack
- API Gateway with TLS
- Three-tier application deployment
- Comprehensive documentation

### Future Enhancements
- Multi-region failover
- GitOps workflow (ArgoCD)
- Advanced network policies
- Backup automation & DR testing
- Cost optimization automation
- Security scanning in CI/CD

## Support

For issues or questions:
1. Check relevant documentation (CONFIG.md, OPERATIONS.md, MONITORING.md)
2. Review logs: `kubectl logs -f deployment/<service>`
3. Check Grafana dashboards for metrics
4. Consult troubleshooting section in [OPERATIONS.md](docs/OPERATIONS.md)

## License

This project is provided as-is for educational and deployment purposes.

---

**Version**: 1.0  
**Last Updated**: 2026-03-29  
**Maintainer**: DevOps/SRE Team
