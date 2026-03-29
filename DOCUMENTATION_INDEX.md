# Documentation Index & Navigation Guide

Quick reference guide to find the right documentation for your task.

## 📋 What Do You Need?

### 🚀 Quick Start (5 minutes)
1. Read [README.md](README.md) - Overview and quick deployment  
2. Run `./scripts/deploy.sh` - Automated deployment  
3. Access services (see [README.md](README.md#quick-deployment))

### 📐 Understanding the Architecture
- **System Design**: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
  - 4 ASCII diagrams (system, infrastructure, Kubernetes, monitoring)
  - Cloud infrastructure breakdown (VNet, AKS, ACR, PostgreSQL)
  - Data flow patterns
  - Disaster recovery strategy

- **Infrastructure Code**: [terraform/README.md](terraform/README.md)
  - Terraform module architecture
  - Module descriptions
  - Variable and output reference

- **Application Deployment**: [helm-charts/README.md](helm-charts/README.md)
  - Helm chart structure
  - Common library design
  - Service customization

### 🔧 Deploying or Reconfiguring

**First Time Deployment**:
1. [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) - Step-by-step guide with all commands
2. [terraform/README.md](terraform/README.md) - Terraform details
3. [helm-charts/README.md](helm-charts/README.md) - Helm deployment details

**Customizing Configuration**:
1. [docs/CONFIG.md](docs/CONFIG.md) - Complete configuration reference
2. Specific files:
   - Infrastructure: [terraform/environments/prod.tfvars](terraform/environments/prod.tfvars)
   - Frontend: [helm-charts/services/frontend/values.yaml](helm-charts/services/frontend/values.yaml)
   - API: [helm-charts/services/api/values.yaml](helm-charts/services/api/values.yaml)
   - Monitoring: [monitoring/prometheus/prometheus.yml](monitoring/prometheus/prometheus.yml)

**Scaling or Updating**:
- [docs/OPERATIONS.md](docs/OPERATIONS.md#scaling--performance) - Scaling section
- [docs/OPERATIONS.md](docs/OPERATIONS.md#daily-operations) - Update procedures

### 📊 Monitoring & Observability

**Getting Started with Monitoring**:
1. [docs/MONITORING.md](docs/MONITORING.md) - Complete monitoring guide
2. Access Grafana: `kubectl port-forward -n monitoring svc/grafana 3000:80`
3. [monitoring/README.md](monitoring/README.md) - Quick setup

**Understanding Metrics**:
- [docs/MONITORING.md](docs/MONITORING.md#key-dashboards) - Dashboards overview
- [docs/MONITORING.md](docs/MONITORING.md#important-alerts) - Alert rules
- [docs/CONFIG.md](docs/CONFIG.md#prometheus-configuration) - Metric configuration

**Setting up Alerts**:
- [monitoring/prometheus/alerts.yml](monitoring/prometheus/alerts.yml) - Alert rules
- [docs/OPERATIONS.md](docs/OPERATIONS.md#monitoring--alerting) - Alert management

**SLO/SLI Tracking**:
- [docs/MONITORING.md](docs/MONITORING.md#sloasli-definitions) - SLO definitions
- [docs/MONITORING.md](docs/MONITORING.md#availability-dashboard-creation) - Availability dashboard

### 🔒 Security & Hardening

**Network Security**:
- [terraform/modules/networking/main.tf](terraform/modules/networking/main.tf) - NSG rules
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md#security) - Security architecture

**Pod Security**:
- [helm-charts/common-lib/templates/deployment.yaml](helm-charts/common-lib/templates/deployment.yaml) - Pod security context
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md#pod-security) - Pod security details

**Secrets Management**:
- [docs/CONFIG.md](docs/CONFIG.md#secrets-management) - Secrets configuration
- [helm-charts/common-lib/templates/secret.yaml](helm-charts/common-lib/templates/secret.yaml) - Secret template

### 🛠️ Operations & Troubleshooting

**Daily Operations**:
- [docs/OPERATIONS.md](docs/OPERATIONS.md#daily-operations) - Daily health checks
- [docs/OPERATIONS.md](docs/OPERATIONS.md#monitoring--alerting) - Dashboard monitoring

**Scaling Services**:
- [docs/OPERATIONS.md](docs/OPERATIONS.md#scaling--performance) - Scaling procedures
- [docs/CONFIG.md](docs/CONFIG.md#autoscaling) - HPA configuration

**Disaster Recovery**:
- [docs/OPERATIONS.md](docs/OPERATIONS.md#disaster-recovery) - Recovery procedures
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md#disaster-recovery) - Recovery strategy

**Troubleshooting**:
- [docs/OPERATIONS.md](docs/OPERATIONS.md#troubleshooting) - Comprehensive troubleshooting guide
- [docs/OPERATIONS.md](docs/OPERATIONS.md#incident-response) - Incident response playbooks
- [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md#troubleshooting) - Deployment troubleshooting

### 🚨 Handle Incident

**Application is Down**:
1. Check pod status: `kubectl get pods -n default`
2. Check logs: `kubectl logs deployment/voting-app-api`
3. [docs/OPERATIONS.md](docs/OPERATIONS.md#api-response-timeout) - Timeout troubleshooting
4. [docs/OPERATIONS.md](docs/OPERATIONS.md#incident-response) - Incident response

**High Error Rate**:
1. [docs/OPERATIONS.md](docs/OPERATIONS.md#alert-firing---high-error-rate) - High error rate response
2. Check database: [docs/OPERATIONS.md](docs/OPERATIONS.md#database-connection-timeout)
3. Scale API: [docs/OPERATIONS.md](docs/OPERATIONS.md#manual-scaling)

**Database Issues**:
1. [docs/OPERATIONS.md](docs/OPERATIONS.md#database-connection-timeout) - Connection issues
2. [docs/OPERATIONS.md](docs/OPERATIONS.md#disaster-recovery) - Database recovery
3. [docs/CONFIG.md](docs/CONFIG.md#database-configuration) - Database config reference

**Monitoring Not Working**:
1. [docs/OPERATIONS.md](docs/OPERATIONS.md#prometheus-not-scraping-metrics) - Prometheus issues
2. [docs/MONITORING.md](docs/MONITORING.md#troubleshooting) - Monitoring troubleshooting
3. [monitoring/prometheus/prometheus.yml](monitoring/prometheus/prometheus.yml) - Scrape config

**TLS/HTTPS Problems**:
1. [docs/OPERATIONS.md](docs/OPERATIONS.md#tls-certificate-error) - Certificate issues
2. [docs/CONFIG.md](docs/CONFIG.md#tls-certificate) - Certificate management

### 💰 Cost Optimization

- [README.md](README.md#cost-optimization) - Cost recommendations
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md#cost-optimization) - Cost strategies
- Estimated cost: $370-530/month

---

## 📚 Complete File Structure & Descriptions

```
voting-app/
│
├── README.md                           # START HERE - Project overview & quick deployment
├── COMPLETION.md                       # Verification that all technical challenge steps are complete
├── DOCUMENTATION_INDEX.md              # This file - navigation guide
│
├── docs/
│   ├── ARCHITECTURE.md                 # System design, infrastructure, data flows (4 diagrams)
│   ├── DEPLOYMENT.md                   # Step-by-step deployment with all commands
│   ├── OPERATIONS.md                   # Daily operations, scaling, disaster recovery, runbooks
│   ├── MONITORING.md                   # Monitoring setup, metrics, dashboards, SLO/SLI
│   └── CONFIG.md                       # Configuration reference for all components
│
├── terraform/                          # Infrastructure as Code
│   ├── README.md                       # Terraform module documentation
│   ├── main.tf                         # Module orchestration
│   ├── variables.tf                    # Input variables
│   ├── outputs.tf                      # Resource outputs
│   ├── modules/
│   │   ├── networking/main.tf          # VNet, subnets, NSGs (3 subnets, detailed rules)
│   │   ├── aks_cluster/main.tf         # AKS cluster (1.29.0, 3-5 nodes)
│   │   ├── acr/main.tf                 # Azure Container Registry
│   │   └── db/main.tf                  # PostgreSQL Flexible Server (v16, 7-day backups)
│   └── environments/
│       ├── README.md                   # Environment setup guide
│       ├── dev.tfvars                  # Dev environment (3 nodes)
│       ├── prod.tfvars                 # Prod environment (5 nodes)
│       ├── backend-dev.hcl             # Dev state isolation
│       └── backend-prod.hcl            # Prod state isolation
│
├── helm-charts/                        # Kubernetes deployment
│   ├── README.md                       # Helm charts guide
│   ├── common-lib/                     # Reusable templates
│   │   ├── Chart.yaml                  # Library chart metadata
│   │   ├── README.md                   # Library usage
│   │   └── templates/
│   │       ├── deployment.yaml         # Reusable deployment template
│   │       ├── service.yaml            # Service template
│   │       ├── configmap.yaml          # ConfigMap template
│   │       ├── secret.yaml             # Secret template
│   │       ├── hpa.yaml                # HorizontalPodAutoscaler template
│   │       └── _helpers.tpl            # Helm helper functions
│   │
│   ├── services/
│   │   ├── frontend/                   # React frontend service
│   │   │   ├── Chart.yaml
│   │   │   └── values.yaml             # 3 replicas, port 3000, HPA max 5
│   │   ├── api/                        # REST API service
│   │   │   ├── Chart.yaml
│   │   │   └── values.yaml             # 3-10 replicas, port 8080, HPA with RPS
│   │   └── worker/                     # Background worker service
│   │       ├── Chart.yaml
│   │       └── values.yaml             # 1-5 replicas, background jobs
│   └── ingress-controller/             # NGINX Ingress Controller
│       ├── values.yaml                 # NGINX config, TLS, rate limit
│       ├── custom-headers.yaml         # Security headers (HSTS, CSP, etc.)
│       └── ingress.yaml                # Routing rules, TLS, path-based routing
│
├── monitoring/                         # Observability stack
│   ├── README.md                       # Monitoring quick start
│   ├── prometheus/                     # Metrics collection
│   │   ├── values.yaml                 # Prometheus Helm chart (15d retention, 50GB)
│   │   ├── prometheus.yml              # Scrape configuration (20+ targets)
│   │   └── alerts.yml                  # Alert rules (20+ rules)
│   ├── grafana/                        # Metrics visualization
│   │   ├── values.yaml                 # Grafana Helm chart, datasources
│   │   └── dashboards/
│   │       └── application.json        # Pre-configured application dashboard
│   ├── otel-collector/                 # Trace aggregation
│   │   └── values.yaml                 # OpenTelemetry Collector config
│   └── blackbox/                       # External probing
│       ├── values.yaml                 # Blackbox Exporter config
│       └── targets.yml                 # Probe targets (5+)
│
├── scripts/
│   └── deploy.sh                       # Automated 10-step deployment (300+ lines)
│
└── README.md                           # Main project README
```

---

## 🔍 Finding Specific Configurations

### Terraform Variables
→ [terraform/variables.tf](terraform/variables.tf) + [docs/CONFIG.md](docs/CONFIG.md)

### Kubernetes Deployments
→ [helm-charts/services/](helm-charts/services/)

### Monitoring Scrape Config
→ [monitoring/prometheus/prometheus.yml](monitoring/prometheus/prometheus.yml)

### Alert Rules
→ [monitoring/prometheus/alerts.yml](monitoring/prometheus/alerts.yml)

### Grafana Dashboards
→ [monitoring/grafana/dashboards/](monitoring/grafana/dashboards/)

### Database Schema
→ [docs/CONFIG.md](docs/CONFIG.md#database-configuration)

### Security Groups/NSGs
→ [terraform/modules/networking/main.tf](terraform/modules/networking/main.tf)

### Pod Security Context
→ [helm-charts/common-lib/templates/deployment.yaml](helm-charts/common-lib/templates/deployment.yaml)

### Deployment Procedure
→ [scripts/deploy.sh](scripts/deploy.sh) or [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)

---

## 🎯 Common Tasks

| Task | Where to Find |
|------|---|
| Deploy application | [scripts/deploy.sh](scripts/deploy.sh) or [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) |
| Change environment | [terraform/environments/](terraform/environments/) |
| Configure monitoring | [docs/CONFIG.md](docs/CONFIG.md#monitoring-configuration) + [monitoring/prometheus/prometheus.yml](monitoring/prometheus/prometheus.yml) |
| Add alert rule | [monitoring/prometheus/alerts.yml](monitoring/prometheus/alerts.yml) |
| Scale services | [docs/OPERATIONS.md](docs/OPERATIONS.md#scaling--performance) |
| Customize Helm charts | [helm-charts/services/*/values.yaml](helm-charts/services/) |
| Update API image | [docs/OPERATIONS.md](docs/OPERATIONS.md#update-application) |
| Rollback deployment | [docs/OPERATIONS.md](docs/OPERATIONS.md#rollback-deployment) |
| Access logs | [docs/OPERATIONS.md](docs/OPERATIONS.md#log-review) |
| Check alerts | [docs/OPERATIONS.md](docs/OPERATIONS.md#monitoring--alerting) |
| Handle pod crash | [docs/OPERATIONS.md](docs/OPERATIONS.md#pod-stuck-in-pending) |
| Database recovery | [docs/OPERATIONS.md](docs/OPERATIONS.md#database-failure) |

---

## 📖 Reading Order (Sequential Learning)

**For New Team Members** (2-3 hours):
1. [README.md](README.md) - 5 min overview
2. [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) - 20 min system design
3. [terraform/README.md](terraform/README.md) - 15 min infrastructure
4. [helm-charts/README.md](helm-charts/README.md) - 15 min applications
5. [docs/MONITORING.md](docs/MONITORING.md) - 20 min observability
6. [docs/OPERATIONS.md](docs/OPERATIONS.md#daily-operations) - 15 min operations

**For DevOps/SRE** (1 hour):
1. [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) - System design
2. [docs/CONFIG.md](docs/CONFIG.md) - All configurations
3. [docs/OPERATIONS.md](docs/OPERATIONS.md) - Operations procedures
4. [docs/MONITORING.md](docs/MONITORING.md) - Monitoring setup

**For Developers** (1 hour):
1. [README.md](README.md#quick-deployment) - Quick start
2. [helm-charts/README.md](helm-charts/README.md) - How to customize charts
3. [docs/CONFIG.md](docs/CONFIG.md#api-configuration) - API configuration
4. [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md#application-deployment) - Deployment

---

## 💡 Quick Tips

- **Stuck?** First check [docs/OPERATIONS.md](docs/OPERATIONS.md#troubleshooting)
- **Want to scale?** See [docs/OPERATIONS.md](docs/OPERATIONS.md#scaling--performance)
- **Need to understand data flow?** Check [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md#data-flows)
- **Looking for SLO/SLI?** Go to [docs/MONITORING.md](docs/MONITORING.md#sloasli-definitions)
- **Need to set up monitoring?** Follow [docs/MONITORING.md](docs/MONITORING.md) or [monitoring/README.md](monitoring/README.md)
- **Deploying first time?** Use [scripts/deploy.sh](scripts/deploy.sh) or follow [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) step-by-step

---

## ✅ Verification Checklist

Before going production, ensure:

- [ ] All steps in [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) completed
- [ ] Monitoring stack running: `kubectl get pods -n monitoring`
- [ ] Application services healthy: `kubectl get pods -n default`
- [ ] Grafana accessible and dashboards loading
- [ ] Prometheus scraping all targets
- [ ] LoadBalancer IP assigned and application accessible
- [ ] Database connectivity verified
- [ ] All alert rules firing correctly
- [ ] Backup strategy in place
- [ ] Team trained on [docs/OPERATIONS.md](docs/OPERATIONS.md) procedures

---

## 📞 Support Resources

| Issue Type | Reference |
|---|---|
| Infrastructure questions | [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) + [terraform/README.md](terraform/README.md) |
| Deployment issues | [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md#troubleshooting) |
| Pod/Container issues | [docs/OPERATIONS.md](docs/OPERATIONS.md#troubleshooting) |
| Monitoring issues | [docs/MONITORING.md](docs/MONITORING.md#troubleshooting) |
| Configuration questions | [docs/CONFIG.md](docs/CONFIG.md) |
| Operational procedures | [docs/OPERATIONS.md](docs/OPERATIONS.md) |
| Emergency incident | [docs/OPERATIONS.md](docs/OPERATIONS.md#incident-response) |

---

**Version**: 1.0  
**Last Updated**: March 29, 2026

---

**🎉 Ready to get started?** Begin with [README.md](README.md#quick-deployment)
