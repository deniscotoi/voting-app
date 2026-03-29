# Configuration Reference

Complete configuration reference for all components of the three-tier voting application.

## Terraform Configuration

### Root Variables (`terraform/variables.tf`)

```hcl
variable "project_name" {
  type        = string
  description = "Project prefix for all resources"
  # Example: "voting-app"
}

variable "location" {
  type        = string
  description = "Azure region"
  default     = "westeurope"
  # Other options: eastus, westus2, northeurope, etc.
}

variable "environment" {
  type        = string
  description = "Environment name (dev, prod)"
  # Validates: must be dev or prod
}

variable "kubernetes_node_count" {
  type        = number
  description = "AKS node count (minimum 3)"
  default     = 3
  # dev: 3, prod: 5 minimum
}

variable "kubernetes_node_vm_size" {
  type        = string
  description = "AKS node VM size"
  default     = "Standard_DS2_v2"
  # Options: Standard_B2s, Standard_D2s_v3, Standard_DS2_v2, etc.
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version"
  default     = "1.29.0"
}

variable "db_admin_username" {
  type        = string
  description = "PostgreSQL admin username"
  default     = "pgadmin"
}

variable "db_admin_password" {
  type        = string
  description = "PostgreSQL admin password (min 12 chars)"
  sensitive   = true
  # Use Azure Key Vault in production
}
```

### Environment Variables

**Development** (`terraform/environments/dev.tfvars`):
```hcl
project_name              = "voting-app"
environment               = "dev"
location                  = "westeurope"
kubernetes_node_count     = 3
kubernetes_node_vm_size   = "Standard_DS2_v2"
db_admin_username         = "pgadmin"
db_admin_password         = "<dev-password>"
```

**Production** (`terraform/environments/prod.tfvars`):
```hcl
project_name              = "voting-app"
environment               = "prod"
location                  = "westeurope"
kubernetes_node_count     = 5
kubernetes_node_vm_size   = "Standard_DS2_v2"
db_admin_username         = "pgadmin"
db_admin_password         = "<prod-password-from-keyvault>"
```

### Terraform Outputs

```hcl
# Resource Group
output "resource_group_name" { value = "voting-app-prod-rg" }

# Networking
output "vnet_id"              { value = "resource-id" }
output "aks_subnet_id"        { value = "resource-id" }
output "db_subnet_id"         { value = "resource-id" }
output "monitoring_subnet_id" { value = "resource-id" }

# Kubernetes
output "aks_name"     { value = "voting-app-prod-aks" }
output "kube_config"  { value = "<kubeconfig-yaml>" }

# Registry
output "acr_login_server" { value = "votingappacr.azurecr.io" }

# Database
output "db_host"     { value = "voting-app-prod-pg.postgres.database.azure.com" }
output "db_name"     { value = "votingapp" }
output "db_username" { value = "pgadmin@voting-app-prod-pg" }
```

## Kubernetes Configuration

### Namespaces

```bash
kubectl create namespace monitoring
kubectl create namespace ingress-nginx
# default namespace for application services
```

### RBAC Roles

Services run with limited permissions:

**voting-app-api ServiceAccount**:
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: voting-app-api
  namespace: default
```

Bound to minimal role (read ConfigMaps, Secrets, etc.)

### Network Policies (Optional)

Enable microsegmentation:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: default
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-api
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: frontend
```

## Helm Charts Configuration

### Common Library (`helm-charts/common-lib/`)

**Default values**:

```yaml
replicaCount: 3
containerPort: 8080
metricsPort: 8080

image:
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80

resources:
  requests:
    cpu: 100m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 512Mi

livenessProbe:
  initialDelaySeconds: 30
  periodSeconds: 10
  failureThreshold: 3

readinessProbe:
  initialDelaySeconds: 10
  periodSeconds: 5
  failureThreshold: 3

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80
```

### Frontend Service (`helm-charts/services/frontend/values.yaml`)

```yaml
replicaCount: 3
image:
  repository: votingappacr.azurecr.io/voting-app-frontend
  tag: "1.0.0"

containerPort: 3000

service:
  type: ClusterIP
  port: 80
  targetPort: 3000

resources:
  requests:
    cpu: 50m
    memory: 128Mi
  limits:
    cpu: 200m
    memory: 256Mi

configMap:
  data:
    REACT_APP_API_URL: "https://api.voting-app.example.com"
    REACT_APP_ENVIRONMENT: "production"

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 5
  targetCPUUtilizationPercentage: 70
```

### API Service (`helm-charts/services/api/values.yaml`)

```yaml
replicaCount: 3
image:
  repository: votingappacr.azurecr.io/voting-app-api
  tag: "1.0.0"

containerPort: 8080
metricsPort: 8080

resources:
  requests:
    cpu: 100m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 512Mi

configMap:
  data:
    LOG_LEVEL: "info"
    ENVIRONMENT: "production"
    DATABASE_HOST: "voting-app-prod-pg.postgres.database.azure.com"
    DATABASE_PORT: "5432"
    DATABASE_NAME: "votingapp"
    DATABASE_SSLMODE: "require"

secrets:
  DATABASE_USER: "pgadmin@voting-app-prod-pg"
  DATABASE_PASSWORD: "<from-keyvault>"

livenessProbe:
  httpGet:
    path: /api/v1/health

readinessProbe:
  httpGet:
    path: /api/v1/ready

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
```

### Worker Service (`helm-charts/services/worker/values.yaml`)

```yaml
replicaCount: 2
image:
  repository: votingappacr.azurecr.io/voting-app-worker
  tag: "1.0.0"

resources:
  requests:
    cpu: 100m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 512Mi

configMap:
  data:
    LOG_LEVEL: "info"
    QUEUE_TYPE: "postgresql"
    BATCH_PROCESS_SIZE: "100"
    PROCESS_INTERVAL: "30s"

autoscaling:
  enabled: true
  minReplicas: 1
  maxReplicas: 5
```

## Monitoring Configuration

### Prometheus (`monitoring/prometheus/values.yaml`)

```yaml
prometheus:
  prometheusSpec:
    retention: 15d                      # Keep metrics for 15 days
    storageSpec:
      volumeClaimTemplate:
        spec:
          resources:
            requests:
              storage: 50Gi             # Adjust based on metrics volume
    scrapeInterval: 30s                 # Scrape every 30 seconds
    evaluationInterval: 30s             # Evaluate alerts every 30s
```

### Grafana (`monitoring/grafana/values.yaml`)

```yaml
replicas: 1

adminUser: admin
adminPassword: prom-operator            # Change in production!

persistence:
  enabled: true
  size: 10Gi                            # Storage for dashboards

datasources:
  datasources.yaml:
    datasources:
      - name: Prometheus
        type: prometheus
        url: http://prometheus-kube-prometheus-prometheus.monitoring.svc:9090
        isDefault: true
```

### OpenTelemetry Collector (`monitoring/otel-collector/values.yaml`)

```yaml
config:
  receivers:
    otlp:
      protocols:
        grpc:
          endpoint: 0.0.0.0:4317        # gRPC endpoint
        http:
          endpoint: 0.0.0.0:4318        # HTTP endpoint
  
  exporters:
    prometheusremotewrite:
      endpoint: "http://prometheus-kube-prometheus-prometheus.monitoring.svc:9090/api/v1/write"
```

**Application should send traces to**: `http://otel-collector:4317`

### Blackbox Exporter (`monitoring/blackbox/values.yaml`)

```yaml
config.modules:
  http_2xx:
    prober: http
    timeout: 5s
    http:
      method: GET
      valid_status_codes: []
  
  tcp_connect:
    prober: tcp
    timeout: 5s
```

## Database Configuration

### PostgreSQL Connection String

```
postgresql://pgadmin@voting-app-prod-pg:PASSWORD@voting-app-prod-pg.postgres.database.azure.com:5432/votingapp?sslmode=require
```

### Required Schemas

```sql
-- Create tables
CREATE TABLE votes (
    id SERIAL PRIMARY KEY,
    option VARCHAR(10) NOT NULL,
    voted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    user_id VARCHAR(255),
    ip_address INET
);

CREATE TABLE vote_results (
    option VARCHAR(10) PRIMARY KEY,
    count INTEGER DEFAULT 0,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_votes_option ON votes(option);
CREATE INDEX idx_votes_voted_at ON votes(voted_at);
```

## API Configuration

### Health Endpoints

**Liveness Probe**:
```
GET /api/v1/health
Response: { "status": "ok" }
```

**Readiness Probe**:
```
GET /api/v1/ready
Response: { "ready": true, "db": true }
```

### Metrics Endpoint

```
GET /metrics
Response: Prometheus format
```

### Environment Variables

| Variable | Example | Purpose |
|----------|---------|---------|
| `DATABASE_HOST` | `voting-app-prod-pg...` | PostgreSQL server |
| `DATABASE_PORT` | `5432` | PostgreSQL port |
| `DATABASE_NAME` | `votingapp` | Database name |
| `DATABASE_USER` | `pgadmin@...` | Database user |
| `DATABASE_PASSWORD` | `<secure>` | Database password |
| `LOG_LEVEL` | `info` | Logging level |
| `API_PORT` | `8080` | API listen port |
| `ENVIRONMENT` | `production` | Environment name |

## Ingress Configuration

### NGINX Ingress Rules (`helm-charts/ingress-controller/ingress.yaml`)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: voting-app
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - api.voting-app.example.com
        - voting-app.example.com
      secretName: voting-app-tls
  rules:
    - host: api.voting-app.example.com
      http:
        paths:
          - path: /api/v1/vote
            backend:
              service:
                name: voting-app-api
                port: { number: 8080 }
    - host: voting-app.example.com
      http:
        paths:
          - path: /
            backend:
              service:
                name: voting-app-frontend
                port: { number: 80 }
```

### TLS Certificate

**Via Let's Encrypt** (automated):
```
cert-manager annotation: cert-manager.io/cluster-issuer: "letsencrypt-prod"
Certificate auto-created in `voting-app-tls` secret
```

**Manual Certificate**:
```bash
kubectl create secret tls voting-app-tls \
    --cert=path/to/cert.pem \
    --key=path/to/key.pem
```

## Secrets Management

### Kubernetes Secrets

```bash
# Create secret
kubectl create secret generic api-secrets \
    --from-literal=DATABASE_USER="pgadmin@..." \
    --from-literal=DATABASE_PASSWORD="<secure>"

# Reference in Helm values
secrets:
  DATABASE_USER: "..."
  DATABASE_PASSWORD: "..."
```

### Azure Key Vault (Recommended for Production)

```bash
# Store secret
az keyvault secret set \
    --vault-name voting-app-kv \
    --name db-password \
    --value "<strong-password>"

# Reference in pod using CSI driver
```

---

**Next**: See [OPERATIONS.md](OPERATIONS.md) for operational runbooks.
