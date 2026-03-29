# Helm Charts for Three-Tier Voting Application

Complete production-ready Helm charts for deploying the voting application and monitoring stack on Kubernetes.

## Directory Structure

```
helm-charts/
├── README.md                          # This file
├── common-lib/                        # Shared library chart (reusable templates)
│   ├── Chart.yaml
│   ├── README.md
│   └── templates/
│       ├── deployment.yaml           # Pod spec with resource limits, health checks
│       ├── service.yaml              # Service configuration
│       ├── configmap.yaml            # Environment configuration
│       ├── secret.yaml               # Sensitive data
│       ├── hpa.yaml                  # Horizontal Pod Autoscaler
│       └── _helpers.tpl              # Common template functions
│
├── services/                          # Service-specific charts
│   ├── frontend/                     # React/Vue frontend
│   │   ├── Chart.yaml
│   │   └── values.yaml
│   ├── api/                          # REST API backend
│   │   ├── Chart.yaml
│   │   └── values.yaml
│   └── worker/                       # Background job processor
│       ├── Chart.yaml
│       └── values.yaml
│
└── ingress-controller/               # API Gateway (NGINX Ingress)
    ├── Chart.yaml
    ├── values.yaml
    ├── custom-headers.yaml           # Security headers
    └── ingress.yaml                  # Ingress rules for all services
```

## Architecture

```
┌────────────────────────────────────────────────────────────┐
│                    NGINX Ingress Controller                 │
│               (Load Balancer / Public IP)                   │
└────────────────────────────────────────────────────────────┘
         │                          │
         ▼                          ▼
┌──────────────────────┐  ┌──────────────────────┐
│   Frontend Service   │  │    API Service       │
│  (voting-app-ui)    │  │  (voting-app-api)    │
│   - Node.js/React   │  │   - Python/Java/Go   │
│   - 3 Replicas      │  │   - 3-10 Replicas    │
│   - HPA enabled     │  │   - HPA + DB access  │
└──────────────────────┘  └──────────────────────┘
         └──────────────────────┬─────────────────┘
                                │
                                ▼
                   ┌──────────────────────┐
                   │    PostgreSQL DB     │
                   │  (Managed Service)   │
                   └──────────────────────┘

         ┌───────────────────────────────────┐
         │   Background Worker               │
         │   (voting-app-worker)             │
         │   - Async job processing          │
         │   - 1-5 Replicas                  │
         │   - Independent scaling           │
         └───────────────────────────────────┘
```

## Quick Start

### 1. Prerequisites

```bash
# Kubernetes cluster running (AKS from Terraform)
kubectl cluster-info

# Helm 3.x installed
helm version

# Container images pushed to ACR
az acr login --name <acr-name>
```

### 2. Deploy Ingress Controller

```bash
# Add NGINX Helm repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install NGINX Ingress Controller
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --values helm-charts/ingress-controller/values.yaml

# Verify LoadBalancer IP assigned
kubectl get svc -n ingress-nginx
```

### 3. Deploy Application Services

```bash
# Update image tags in values.yaml with actual ACR image URIs

# Frontend
helm install frontend helm-charts/services/frontend \
  --namespace default \
  --values helm-charts/services/frontend/values.yaml

# API
helm install api helm-charts/services/api \
  --namespace default \
  --values helm-charts/services/api/values.yaml

# Worker
helm install worker helm-charts/services/worker \
  --namespace default \
  --values helm-charts/services/worker/values.yaml
```

### 4. Deploy Ingress Rules

```bash
kubectl apply -f helm-charts/ingress-controller/ingress.yaml
```

### 5. Verify Deployment

```bash
# Check all services
kubectl get all -n default

# Verify pods are running
kubectl get pods -n default

# Check Ingress
kubectl get ingress

# Test connectivity
kubectl port-forward svc/api 8080:8080
curl http://localhost:8080/api/v1/health
```

## Customization

### Environment-Specific Values

Create environment-specific overrides:

```bash
# Development
helm upgrade frontend helm-charts/services/frontend \
  --namespace default \
  -f helm-charts/services/frontend/values.yaml \
  -f helm-charts/services/frontend/values-dev.yaml

# Production
helm upgrade frontend helm-charts/services/frontend \
  --namespace default \
  -f helm-charts/services/frontend/values.yaml \
  -f helm-charts/services/frontend/values-prod.yaml
```

### Scaling Services

```bash
# Manual replica count
helm upgrade api helm-charts/services/api \
  --set replicaCount=5

# Enable autoscaling
helm upgrade api helm-charts/services/api \
  --set autoscaling.enabled=true \
  --set autoscaling.maxReplicas=10
```

### Database Credentials

**NEVER commit database passwords to Git!**

Use Kubernetes Secrets or Azure Key Vault:

```bash
# Option 1: Create secret manually
kubectl create secret generic api-db \
  --from-literal=DATABASE_USER=pgadmin \
  --from-literal=DATABASE_PASSWORD='<strong-password>'

# Option 2: Use Azure Key Vault (recommended for prod)
# See section below
```

### Azure Key Vault Integration

For production secret management:

```bash
# 1. Create Key Vault
az keyvault create --resource-group <rg> --name <kv-name>

# 2. Add secret
az keyvault secret set --vault-name <kv-name> --name db-password --value '<password>'

# 3. Reference in Helm values
# Use CSI Driver or managed identity to fetch secrets
```

## Monitoring Integration

### ServiceMonitor for Prometheus

Pods expose metrics on port 8080:

```yaml
# Automatically scraped if pod has annotation:
podAnnotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "8080"
  prometheus.io/path: "/metrics"
```

### Application Metrics

Each service should expose Prometheus metrics:

- `/metrics` - Standard Prometheus format
- Include request rate, latency, error rate
- Include custom business metrics

## Health Checks

### Liveness Probe
Restarts pod if unhealthy (e.g., memory leak, deadlock)

### Readiness Probe
Removes pod from load balancer if not ready to serve traffic

```yaml
livenessProbe:
  httpGet:
    path: /health
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /ready
  initialDelaySeconds: 10
  periodSeconds: 5
```

## Autoscaling

Horizontal Pod Autoscaler (HPA) scales replicas based on:

- CPU utilization (target: 70%)
- Memory utilization (target: 80%)
- Custom metrics (requests/sec)

```bash
# View HPA status
kubectl get hpa

# Manual scale
kubectl scale deployment frontend --replicas=5
```

## Resource Management

### Requests (minimum guaranteed)
```yaml
resources:
  requests:
    cpu: 100m        # 0.1 CPU cores
    memory: 256Mi    # 256 megabytes
```

### Limits (maximum allowed)
```yaml
resources:
  limits:
    cpu: 500m        # 0.5 CPU cores
    memory: 512Mi    # 512 megabytes
```

If pod exceeds limits, it gets evicted/killed.

## Networking

### Service Discovery
Services accessible via DNS:
- `voting-app-frontend.default.svc.cluster.local`
- `voting-app-api.default.svc.cluster.local`
- `voting-app-worker.default.svc.cluster.local`

### Ingress Routing
Public routes defined in `ingress-controller/ingress.yaml`:
- `https://voting-app.example.com` → Frontend
- `https://api.voting-app.example.com/api/v1/vote` → API
- `https://api.voting-app.example.com/metrics` → API Metrics

## Upgrades & Rollbacks

### Rolling Update (zero-downtime)
```bash
# Update image
helm upgrade api helm-charts/services/api \
  --set image.tag=v1.2.0

# Original replicas maintained during upgrade
# Old pods drain connections → New pods start → Old pods terminate
```

### Rollback
```bash
# See revision history
helm history api

# Rollback to previous version
helm rollback api 2

# Downgrade to specific version
helm rollback api 1
```

## Troubleshooting

### Pods not starting
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### Image pull errors
```bash
# Check ACR credentials
kubectl get secrets
# Create imagePullSecret if needed
kubectl create secret docker-registry acr-secret \
  --docker-server=<acr>.azurecr.io \
  --docker-username=<username> \
  --docker-password=<password>
```

### Database connection failures
```bash
# Test connectivity
kubectl exec -it <api-pod> -- \
  psql -h <db-host> -U <user> -d votingapp -c "SELECT 1"

# Check environment variables
kubectl exec <api-pod> -- env | grep DATABASE
```

### Resource limits causing crashes
```bash
# Check resource usage
kubectl top pods
kubectl top nodes

# Increase limits in values.yaml
helm upgrade api helm-charts/services/api \
  --set resources.limits.memory=1Gi
```

## Production Checklist

- [ ] All images built and pushed to ACR
- [ ] Database credentials in Azure Key Vault
- [ ] Ingress TLS certificate configured
- [ ] DNS records pointing to LoadBalancer IP
- [ ] Monitoring stack deployed (Prometheus, Grafana)
- [ ] Alert rules configured
- [ ] Pod disruption budgets set
- [ ] RBAC service accounts created
- [ ] Network policies configured
- [ ] Backup strategy documented
- [ ] Autoscaling limits verified
- [ ] Resource requests/limits appropriate

## Next Steps

1. Deploy monitoring stack: `../monitoring/`
2. Configure CI/CD for automated builds
3. Set up secret rotation
4. Implement GitOps with ArgoCD
5. Configure multi-region failover

---

**Version**: 1.0  
**Kubernetes**: >= 1.24  
**Helm**: >= 3.10  
**Last Updated**: 2026-03-29
