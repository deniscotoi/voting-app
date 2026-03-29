# Deployment Guide

Complete step-by-step guide for deploying the three-tier voting application on Azure Kubernetes Service (AKS).

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Infrastructure Provisioning](#infrastructure-provisioning)
3. [Container Registry Setup](#container-registry-setup)
4. [Monitoring Stack Deployment](#monitoring-stack-deployment)
5. [API Gateway Deployment](#api-gateway-deployment)
6. [Application Deployment](#application-deployment)
7. [Database Configuration](#database-configuration)
8. [Verification](#verification)
9. [TLS/SSL Setup](#tlsssl-setup)
10. [Cleanup](#cleanup)

## Prerequisites

### Required Tools
- **Azure CLI** (`az`) - version 2.40+
- **Terraform** - version 1.6.0+
- **kubectl** - version 1.24+
- **Helm** - version 3.10+
- **Docker** - for building images

### Azure Subscription
- Service Principal with Contributor role
- Quota for: 5+ nodes, 50+ vCPUs, 100+ GB storage

### Networking
- DNS domain (for SSL certificate)
- TLS certificate or ability to use Let's Encrypt

## Infrastructure Provisioning

### 1. Deploy with Terraform

```bash
cd terraform

# Initialize Terraform
terraform init -backend-config=environments/backend-prod.hcl

# Validate configuration
terraform validate

# Plan deployment
terraform plan -var-file=environments/prod.tfvars -out=tfplan

# Apply
terraform apply tfplan
```

**Output variables needed:**
```bash
terraform output -raw kube_config > kubeconfig.yaml
export ACR_LOGIN_SERVER=$(terraform output acr_login_server)
export AKS_NAME=$(terraform output aks_name)
export DB_HOST=$(terraform output db_host)
```

### 2. Configure kubectl Access

```bash
# Get Azure credentials
az aks get-credentials \
    --resource-group voting-app-prod-rg \
    --name $(terraform output -raw aks_name) \
    --admin

# Test connectivity
kubectl cluster-info
kubectl get nodes
```

## Container Registry Setup

### 1. Login to ACR

```bash
az acr login --name $(terraform output acr_login_server | cut -d. -f1)
```

### 2. Build Container Images

Assuming Docker files in `docker/{service}/Dockerfile`:

```bash
# Build all services
for service in frontend api worker; do
    az acr build \
        --registry $(terraform output acr_login_server | cut -d. -f1) \
        --image "voting-app-$service:1.0.0" \
        --file "docker/$service/Dockerfile" \
        .
done

# Verify images
az acr repository list --name $(terraform output acr_login_server | cut -d. -f1)
```

### 3. Create Image Pull Secret

```bash
# Get ACR credentials
ACR_NAME=$(terraform output acr_login_server | cut -d. -f1)
REGISTRY=$(terraform output acr_login_server)

# Create secret
kubectl create secret docker-registry acr-secret \
    --docker-server=$REGISTRY \
    --docker-username=$(az acr credential show --name $ACR_NAME --query username -o tsv) \
    --docker-password=$(az acr credential show --name $ACR_NAME --query "passwords[0].value" -o tsv)
```

## Monitoring Stack Deployment

### 1. Add Helm Repositories

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update
```

### 2. Create Monitoring Namespace

```bash
kubectl create namespace monitoring
```

### 3. Deploy Prometheus

```bash
helm install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --values monitoring/prometheus/values.yaml \
    --wait
```

### 4. Deploy Grafana

```bash
helm install grafana grafana/grafana \
    --namespace monitoring \
    --values monitoring/grafana/values.yaml \
    --wait

# Get Grafana admin password
kubectl get secret grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 -d
```

### 5. Deploy OpenTelemetry Collector

```bash
helm install otel-collector open-telemetry/opentelemetry-collector \
    --namespace monitoring \
    --values monitoring/otel-collector/values.yaml \
    --wait
```

### 6. Verify Monitoring

```bash
# Port-forward Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

# Port-forward Grafana
kubectl port-forward -n monitoring svc/grafana 3000:80

# Access:
# Prometheus: http://localhost:9090
# Grafana: http://localhost:3000
```

## API Gateway Deployment

### 1. Add NGINX Helm Repository

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
```

### 2. Create Ingress Namespace

```bash
kubectl create namespace ingress-nginx
```

### 3. Deploy NGINX Ingress Controller

```bash
helm install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace ingress-nginx \
    --values helm-charts/ingress-controller/values.yaml \
    --wait
```

### 4. Get LoadBalancer IP

```bash
# Wait for external IP assignment
kubectl get svc -n ingress-nginx -w

# Extract IP
EXTERNAL_IP=$(kubectl get svc -n ingress-nginx ingress-nginx \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "LoadBalancer IP: $EXTERNAL_IP"
```

### 5. Deploy Ingress Rules

```bash
kubectl apply -f helm-charts/ingress-controller/ingress.yaml
```

## Application Deployment

### 1. Update Image References

Edit each service's `values.yaml` with actual image URIs:

```yaml
# helm-charts/services/api/values.yaml
image:
  repository: <acr>.azurecr.io/voting-app-api
  tag: "1.0.0"
```

### 2. Deploy Frontend

```bash
helm install frontend helm-charts/services/frontend \
    --namespace default \
    --values helm-charts/services/frontend/values.yaml \
    --wait
```

### 3. Deploy API

```bash
# Update Secrets with database credentials
kubectl create secret generic api-secrets \
    --from-literal=DATABASE_USER="pgadmin@voting-app-prod-pg" \
    --from-literal=DATABASE_PASSWORD="<strong-password>"

# Deploy
helm install api helm-charts/services/api \
    --namespace default \
    --values helm-charts/services/api/values.yaml \
    --wait
```

### 4. Deploy Worker

```bash
helm install worker helm-charts/services/worker \
    --namespace default \
    --values helm-charts/services/worker/values.yaml \
    --wait
```

### 5. Verify Deployments

```bash
# Check pods
kubectl get pods -n default

# Check services
kubectl get svc -n default

# Check Ingress
kubectl get ingress
```

## Database Configuration

### 1. Retrieve Database Details

```bash
terraform output db_host
terraform output db_name
terraform output db_username
terraform output db_password
```

### 2. Initialize Database

```bash
# Install psql client (if not present)
# macOS: brew install postgresql
# Ubuntu: sudo apt install postgresql-client
# Windows: Download from postgresql.org

# Connect to database
psql -h $(terraform output -raw db_host) \
     -U $(terraform output -raw db_username) \
     -d $(terraform output -raw db_name)

# Run initialization script
\i scripts/schema.sql
\i scripts/seed-data.sql
```

### 3. Create Database Credentials Secret

```bash
kubectl create secret generic app-db-credentials \
    --from-literal=host=$(terraform output -raw db_host) \
    --from-literal=port=5432 \
    --from-literal=database=$(terraform output -raw db_name) \
    --from-literal=username=$(terraform output -raw db_username) \
    --from-literal=password=$(terraform output -raw db_password)
```

## Verification

### 1. Check Infrastructure

```bash
# Verify Kubernetes nodes
kubectl get nodes
kubectl top nodes

# Verify storage
kubectl get pvc

# Verify Network Policies
kubectl get networkpolicies
```

### 2. Check Application Services

```bash
# Port-forward to API
kubectl port-forward svc/voting-app-api 8080:8080

# Test endpoints
curl http://localhost:8080/api/v1/health
curl http://localhost:8080/api/v1/ready
curl http://localhost:8080/api/v1/results

# Port-forward to Frontend
kubectl port-forward svc/voting-app-frontend 3000:80
open http://localhost:3000
```

### 3. Check Monitoring

```bash
# Verify Prometheus scraping targets
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Visit http://localhost:9090/targets

# Verify metrics collection
kubectl port-forward -n monitoring svc/grafana 3000:80
# Visit http://localhost:3000
```

### 4. Test Full Application Flow

```bash
# 1. Access frontend
curl https://voting-app.example.com/

# 2. Submit vote
curl -X POST https://api.voting-app.example.com/api/v1/vote \
    -H "Content-Type: application/json" \
    -d '{"option": "A"}'

# 3. Check results
curl https://api.voting-app.example.com/api/v1/results

# 4. Check black-box monitoring
kubectl port-forward -n monitoring svc/blackbox-exporter 9115:9115
curl 'http://localhost:9115/probe?target=https://api.voting-app.example.com&module=http_2xx'
```

## TLS/SSL Setup

### Option 1: Let's Encrypt with cert-manager (Recommended)

```bash
# Install cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --set installCRDs=true

# Create ClusterIssuer for Let's Encrypt
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@voting-app.example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF

# Ingress automatically gets certificate
# (already configured in ingress-controller/ingress.yaml with annotation:
#  cert-manager.io/cluster-issuer: "letsencrypt-prod")
```

### Option 2: Bring Your Own Certificate

```bash
# Create secret with certificate
kubectl create secret tls voting-app-tls \
    --cert=path/to/cert.pem \
    --key=path/to/key.pem

# Update Ingress
kubectl patch ingress voting-app \
    -p '{"spec":{"tls":[{"hosts":["api.voting-app.example.com"],"secretName":"voting-app-tls"}]}}'
```

## Cleanup

### Remove Application Deployments

```bash
helm uninstall frontend
helm uninstall api
helm uninstall worker
```

### Remove API Gateway

```bash
helm uninstall ingress-nginx -n ingress-nginx
```

### Remove Monitoring

```bash
helm uninstall prometheus -n monitoring
helm uninstall grafana -n monitoring
helm uninstall otel-collector -n monitoring
```

### Remove Infrastructure (Terraform)

```bash
cd terraform
terraform destroy -var-file=environments/prod.tfvars
```

## Troubleshooting

### Pods not starting
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name> --previous
```

### Database connection failed
```bash
# Check connectivity
kubectl run -it --rm debug --image=alpine --restart=Never -- \
    sh -c "apk add postgresql-client && psql -h <db-host> -U <user> -d <db>"
```

### LoadBalancer IP stuck on Pending
```bash
# Azure: May take several minutes
# Check status
kubectl get svc -n ingress-nginx -w

# Check events
kubectl describe svc -n ingress-nginx ingress-nginx
```

### Memory/CPU pressure
```bash
# Scale down
kubectl scale deployment frontend --replicas=1

# Increase node resources in Terraform
# Edit variables.tf and reapply
```

---

**Next**: See [MONITORING.md](MONITORING.md) for detailed monitoring setup.
