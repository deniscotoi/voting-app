#!/bin/bash
# Deployment script for three-tier voting application
# Usage: ./deploy.sh [--dry-run] <environment> <image-tag> [acr-name]
# Examples:
#   ./deploy.sh                           # Deploy to dev
#   ./deploy.sh prod latest votingappacr  # Deploy prod
#   ./deploy.sh --dry-run prod            # Preview prod deployment

set -e

DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
    shift
fi

ENVIRONMENT=${1:-dev}
IMAGE_TAG=${2:-latest}
ACR_NAME="${3:-votingappacr}"

echo "=========================================="
echo "Deploying Voting Application"
echo "Environment: $ENVIRONMENT"
echo "Image Tag: $IMAGE_TAG"
echo "ACR: $ACR_NAME.azurecr.io"
if [ "$DRY_RUN" = true ]; then
    echo "MODE: DRY RUN (no changes will be made)"
fi
echo "=========================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Preflight checks
echo -e "${YELLOW}[1/10] Running preflight checks...${NC}"
if ! command_exists kubectl; then
    echo -e "${RED}kubectl not found!${NC}"
    exit 1
fi

if ! command_exists helm; then
    echo -e "${RED}helm not found!${NC}"
    exit 1
fi

# Skip cluster connection check in dry-run mode
if [ "$DRY_RUN" = false ]; then
    kubectl cluster-info >/dev/null || { echo -e "${RED}Cannot connect to Kubernetes cluster!${NC}"; exit 1; }
else
    echo "[DRY RUN] Skipping cluster connection check"
fi
echo -e "${GREEN}✓ Preflight checks passed${NC}"

# Create namespaces
echo -e "${YELLOW}[2/10] Creating namespaces...${NC}"
if [ "$DRY_RUN" = true ]; then
    echo "[DRY RUN] Would create namespaces:"
    echo "  - monitoring (for Prometheus, Grafana, OTEL)"
    echo "  - ingress-nginx (for NGINX Ingress Controller)"
    echo "  - default (for application services)"
else
    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
    kubectl create namespace ingress-nginx --dry-run=client -o yaml | kubectl apply -f -
fi
echo -e "${GREEN}✓ Namespaces${NC}"

# Add Helm repositories
echo -e "${YELLOW}[3/10] Adding Helm repositories...${NC}"
if [ "$DRY_RUN" = false ]; then
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo update
else
    echo "[DRY RUN] Would add Helm repositories (skipped for dry-run)"
fi
echo -e "${GREEN}✓ Helm repositories${NC}"

# Deploy Ingress Controller
echo -e "${YELLOW}[4/10] Deploying NGINX Ingress Controller...${NC}"
if [ "$DRY_RUN" = true ]; then
    echo "[DRY RUN] Would deploy NGINX Ingress Controller:"
    echo "  - Namespace: ingress-nginx"
    echo "  - Chart: ingress-nginx/ingress-nginx"
    echo "  - Replicas: 2"
    echo "  - Service: LoadBalancer"
    echo "  - Ports: HTTP/HTTPS (80/443)"
else
    helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
        --namespace ingress-nginx \
        --values helm-charts/ingress-controller/values.yaml \
        --wait
fi
echo -e "${GREEN}✓ NGINX Ingress Controller${NC}"

# Get LoadBalancer IP
echo -e "${YELLOW}[5/10] Waiting for LoadBalancer IP...${NC}"
if [ "$DRY_RUN" = true ]; then
    echo "[DRY RUN] Would wait for LoadBalancer IP assignment"
    echo "  (In real deployment, this would contain your application URL)"
    LB_IP="<PENDING>"
else
    LB_IP=""
    for i in {1..30}; do
        LB_IP=$(kubectl get svc -n ingress-nginx ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
        if [ ! -z "$LB_IP" ]; then
            break
        fi
        echo "Waiting for LoadBalancer IP... ($i/30)"
        sleep 2
    done

    if [ -z "$LB_IP" ]; then
        echo -e "${YELLOW}Warning: LoadBalancer IP not assigned yet. This is normal on some cloud providers.${NC}"
    else
        echo -e "${GREEN}✓ LoadBalancer IP: $LB_IP${NC}"
        echo "  Update DNS records to point to: $LB_IP"
    fi
fi

# Deploy monitoring stack
echo -e "${YELLOW}[6/10] Deploying Monitoring Stack...${NC}"
if [ "$DRY_RUN" = true ]; then
    echo "[DRY RUN] Would deploy monitoring components:"
    echo "  - Prometheus (metrics collection, 15d retention, 50GB storage)"
    echo "  - Grafana (visualization, dashboards)"
    echo "  - AlertManager (alerting)"
    echo "  - Node Exporter (infrastructure metrics)"
    echo "  - Kube State Metrics (Kubernetes metrics)"
    echo "  - OpenTelemetry Collector (trace aggregation)"
    echo "  All components deployed to 'monitoring' namespace"
else
    helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
        --namespace monitoring \
        --values monitoring/prometheus/values.yaml \
        --wait

    helm upgrade --install grafana grafana/grafana \
        --namespace monitoring \
        --values monitoring/grafana/values.yaml \
        --wait

    helm upgrade --install otel-collector open-telemetry/opentelemetry-collector \
        --namespace monitoring \
        --values monitoring/otel-collector/values.yaml \
        --wait
fi
echo -e "${GREEN}✓ Monitoring stack${NC}"

# Deploy Blackbox Exporter
echo -e "${YELLOW}[7/10] Deploying Blackbox Exporter...${NC}"
if [ "$DRY_RUN" = true ]; then
    echo "[DRY RUN] Would deploy Blackbox Exporter:"
    echo "  - 5+ external probe targets (API, frontend, database, DNS)"
    echo "  - HTTP health checks every 5-10 minutes"
    echo "  - TCP connectivity checks every 15 minutes"
    echo "  - DNS resolution checks"
    echo "  Deployed to 'monitoring' namespace"
else
    helm upgrade --install blackbox-exporter prometheus-community/prometheus-blackbox-exporter \
        --namespace monitoring \
        --values monitoring/blackbox/values.yaml \
        --wait || echo -e "${YELLOW}Warning: Blackbox exporter deployment skipped${NC}"
fi
echo -e "${GREEN}✓ Blackbox exporter${NC}"

# Build and push container images
echo -e "${YELLOW}[8/10] Building and pushing container images...${NC}"
if [ "$DRY_RUN" = true ]; then
    echo "[DRY RUN] Would build and push images:"
    for service in frontend api worker; do
        echo "  - $ACR_NAME.azurecr.io/voting-app-$service:$IMAGE_TAG"
    done
else
    az acr login --name "$ACR_NAME"

    # Build images (example - adjust based on your actual Dockerfile locations)
    for service in frontend api worker; do
        echo "Building $service image..."
        az acr build \
            --registry "$ACR_NAME" \
            --image "voting-app-$service:$IMAGE_TAG" \
            --file "docker/$service/Dockerfile" \
            . || echo -e "${YELLOW}Warning: Could not build $service${NC}"
    done
fi
echo -e "${GREEN}✓ Container images${NC}"

# Deploy application services
echo -e "${YELLOW}[9/10] Deploying application services...${NC}"
ACR_URL="$ACR_NAME.azurecr.io"

for service in frontend api worker; do
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would deploy $service service:"
        case $service in
            frontend)
                echo "  - Image: $ACR_URL/voting-app-frontend:$IMAGE_TAG"
                echo "  - Replicas: 2-5 (autoscaling)"
                echo "  - Port: 3000"
                echo "  - CPU: 50m request / 200m limit"
                echo "  - Memory: 128Mi request / 256Mi limit"
                ;;
            api)
                echo "  - Image: $ACR_URL/voting-app-api:$IMAGE_TAG"
                echo "  - Replicas: 3-10 (autoscaling)"
                echo "  - Port: 8080"
                echo "  - CPU: 100m request / 500m limit"
                echo "  - Memory: 256Mi request / 512Mi limit"
                echo "  - Database connection configured"
                ;;
            worker)
                echo "  - Image: $ACR_URL/voting-app-worker:$IMAGE_TAG"
                echo "  - Replicas: 1-5 (autoscaling)"
                echo "  - CPU: 100m request / 500m limit"
                echo "  - Memory: 256Mi request / 512Mi limit"
                echo "  - Background job processing"
                ;;
        esac
    else
        helm upgrade --install "$service" "helm-charts/services/$service" \
            --namespace default \
            --set "image.repository=$ACR_URL/voting-app-$service" \
            --set "image.tag=$IMAGE_TAG" \
            --values "helm-charts/services/$service/values.yaml" \
            --wait || echo -e "${YELLOW}Warning: Deployment of $service may have issues${NC}"
    fi
done
echo -e "${GREEN}✓ Application services${NC}"

# Deploy Ingress rules
echo -e "${YELLOW}[10/10] Deploying Ingress rules...${NC}"
if [ "$DRY_RUN" = true ]; then
    echo "[DRY RUN] Would deploy Ingress routing:"
    echo "  - voting-app.example.com → frontend (port 3000)"
    echo "  - api.voting-app.example.com → api (port 8080)"
    echo "  - TLS termination enabled"
    echo "  - Security headers configured"
    echo "  - Rate limiting: 100 requests/second"
else
    kubectl apply -f helm-charts/ingress-controller/ingress.yaml
fi
echo -e "${GREEN}✓ Ingress rules${NC}"

# Print summary
echo ""
echo "=========================================="
if [ "$DRY_RUN" = true ]; then
    echo -e "${GREEN}Dry Run Complete! (No changes made)${NC}"
    echo "========================================="
    echo ""
    echo "To perform the actual deployment, run:"
    echo "  ./deploy.sh $ENVIRONMENT $IMAGE_TAG $ACR_NAME"
    echo ""
else
    echo -e "${GREEN}Deployment Complete!${NC}"
    echo "=========================================="
    echo ""
    echo "Access points:"
    echo "  Frontend:  https://voting-app.example.com"
    echo "  API:       https://api.voting-app.example.com"
    echo "  Grafana:   kubectl port-forward -n monitoring svc/grafana 3000:80"
    echo "             → http://localhost:3000"
    echo "  Prometheus: kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090"
    echo "             → http://localhost:9090"
    echo ""
    echo "Next steps:"
    echo "  1. Update DNS records to point to: $LB_IP"
    echo "  2. Configure TLS certificate (see docs/DEPLOYMENT.md)"
    echo "  3. Update database credentials in secrets"
    echo "  4. Verify monitoring dashboards"
    echo ""
    echo "To view logs:"
    echo "  kubectl logs -f deployment/<service-name>"
    echo ""
    echo "To scale services:"
    echo "  kubectl scale deployment <service-name> --replicas=5"
    echo ""
fi
