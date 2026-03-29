# Architecture Documentation

Complete system architecture for the three-tier voting application deployment on Azure Kubernetes Service (AKS).

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        Internet Users                            │
│                           (Public)                               │
└──────────────────────────────┬──────────────────────────────────┘
                               │ HTTPS
                               ▼
                    ┌──────────────────────┐
                    │   Azure Load         │
                    │   Balancer (Public)  │
                    │   IP: <external>     │
                    └──────────────────────┘
                               │
                               ▼
        ┌──────────────────────────────────────────┐
        │   NGINX Ingress Controller               │
        │   (API Gateway / L7 Load Balancer)       │
        │   - TLS/SSL Termination                  │
        │   - Path-based routing                   │
        │   - Rate limiting                        │
        │   - Security headers                     │
        └──────────────────────────────────────────┘
                    │                  │
            ┌───────┴──────────┐      │
            │                  │      │
            ▼                  ▼      │
    ┌──────────────────┐  ┌─────────────────┐
    │ Frontend Service │  │  API Service    │
    │ Deployment (3-5) │  │ Deployment (3-10)
    │ - React/Vue UI   │  │ - REST API      │
    │ - Static assets  │  │ - Business logic│
    │ - HPA enabled    │  │ - HPA enabled   │
    └──────────────────┘  └────────┬────────┘
            │                      │
            └──────────────────────┤ IO
                                   │
                         ┌─────────▼──────────┐
                         │ PostgreSQL DB      │
                         │ (Managed Service)  │
                         │ - vpc peering      │
                         │ - 7-day backups    │
                         │ - Monitor export   │
                         └────────────────────┘

         ┌────────────────────────────────────┐
         │  Worker Deployment (1-5)           │
         │  - Background job processor        │
         │  - Queue worker (PostgreSQL)       │
         │  - Async processing                │
         │  - Independent scaling             │
         └────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    Monitoring Tier                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │  Prometheus  │  │   Grafana    │  │ OTEL Collect │           │
│  │  (Metrics)   │  │ (Dashboard)  │  │ (Aggregator) │           │
│  └──────────────┘  └──────────────┘  └──────────────┘           │
│              Alert Manager    Alerting Rules                      │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│               Black-Box Monitoring (External VM)                 │
│  ┌──────────────────────────────────────────────────┐            │
│  │  Prometheus Blackbox Exporter                    │            │
│  │  - Probes API endpoint every 5 min              │            │
│  │  - Reports availability from outside cluster    │            │
│  │  - Aggregates to Prometheus                     │            │
│  └──────────────────────────────────────────────────┘            │
└─────────────────────────────────────────────────────────────────┘
```

## Cloud Infrastructure Layer

### Azure Virtual Network (VNet)

**Address Space**: `10.0.0.0/16` (65,536 IP addresses)

#### Subnets

| Subnet | CIDR | Purpose | Nodes | NSG Rules |
|--------|------|---------|-------|-----------|
| AKS | `10.0.1.0/24` | Kubernetes worker nodes | 3-5 | Allow LB, VNet traffic |
| Database | `10.0.3.0/24` | PostgreSQL flexible server | Managed | Allow port 5432 from VNet |
| Monitoring | `10.0.2.0/24` | External monitoring agents | 1-2 | Allow VNet traffic |

#### Network Security Groups (NSGs)

**AKS NSG**:
- ✅ Allow Azure Load Balancer → any port
- ✅ Allow VNet (10.0.0.0/16) → any port
- ❌ Deny external SSH (port 22)

**Database NSG**:
- ✅ Allow VNet (10.0.0.0/16) → PostgreSQL (5432)
- ❌ Deny all other inbound

**Monitoring NSG**:
- ✅ Allow VNet (10.0.0.0/16) → all
- ✅ Allow outbound to internet (for metrics export)

### Azure Kubernetes Service (AKS)

**Properties**:
- **Version**: 1.29.0+
- **SKU**: Free tier (cost-optimized, limited SLA)
- **CNI**: Azure (cloud-native networking)
- **Load Balancer**: Standard (required for ingress)
- **System Assigned Identity**: Managed Pod Identity enabled

**Node Pool (System)**:
- **Nodes**: 3 (dev) to 5 (prod)
- **VM Size**: Standard_DS2_v2 (2 vCPU, 7 GB RAM)
- **OS**: Linux (Ubuntu)
- **Autoscaling**: Enabled (min 3, max 5 nodes)

**Kubernetes Networking**:
- **Service CIDR**: 10.1.0.0/16
- **DNS Service**: 10.1.0.10
- **Pod CIDR**: Assigned dynamically
- **Network Policy**: Can be enabled for microsegmentation

### Azure Container Registry (ACR)

**Properties**:
- **SKU**: Standard (production-grade)
- **Admin Access**: Disabled (uses managed identity)
- **Image Retention**: Default (tags auto-deleted)
- **Webhooks**: Can integrate with CI/CD

**Images Stored**:
- `<acr>.azurecr.io/voting-app-frontend:1.0.0`
- `<acr>.azurecr.io/voting-app-api:1.0.0`
- `<acr>.azurecr.io/voting-app-worker:1.0.0`

### PostgreSQL Flexible Server

**Properties**:
- **Version**: PostgreSQL 16
- **SKU**: B_Standard_B1ms (1 vCPU, 2 GB RAM) - dev/test only
- **Storage**: 32 GB (auto-scaled)
- **Backup Retention**: 7 days
- **HA Mode**: Disabled (can enable for prod)
- **VNet Integration**: Delegated subnet (10.0.3.0/24)

**Databases**:
- `votingapp` - Main application database

**Monitoring**:
- PostgreSQL exporter metrics scraped by Prometheus

## Kubernetes Architecture

### Namespaces

| Namespace | Purpose | Workloads |
|-----------|---------|-----------|
| `default` | Application services | frontend, api, worker |
| `monitoring` | Observability stack | prometheus, grafana, otel, alertmanager |
| `ingress-nginx` | API Gateway | ingress-controller, webhook |
| `kube-system` | Kubernetes system | coredns, kube-proxy, azure-cni |

### Deployments & Replicas

```
Frontend Deployment
├── Pod replica 1 (voting-app-frontend-abc123)
│   └── Container: nginx (3000/tcp)
├── Pod replica 2 (voting-app-frontend-def456)
└── Pod replica 3 (voting-app-frontend-ghi789)

API Deployment
├── Pod replica 1 (voting-app-api-xyz123)
│   └── Containers: api (8080/tcp)
├── Pod replica 2 (voting-app-api-xyz456)
└── ... (up to 10 replicas)

Worker Deployment
├── Pod replica 1 (voting-app-worker-pqr123)
├── Pod replica 2 (voting-app-worker-pqr456)
└── ... (up to 5 replicas)
```

### Services & Service Discovery

**Frontend Service** (ClusterIP)
```
voting-app-frontend.default.svc.cluster.local:80
→ Load balances to 3-5 frontend pods
```

**API Service** (ClusterIP)
```
voting-app-api.default.svc.cluster.local:8080
→ Load balances to 3-10 api pods
→ Exposes /metrics on same port
```

**Worker Service** (ClusterIP)
```
voting-app-worker.default.svc.cluster.local:8080
→ Load balances to 1-5 worker pods (internal only)
```

### Ingress & Routing

**NGINX Ingress Controller** (LoadBalancer service)
- **External IP**: Assigned by Azure Load Balancer
- **Port 80**: HTTP (redirects to HTTPS)
- **Port 443**: HTTPS/TLS

**Ingress Rules**:
```
voting-app.example.com / → frontend:80
api.voting-app.example.com /api/v1/* → api:8080
```

## Data Flow

### Request Path (User → API)

```
1. User Browser
   └─(HTTPS request)──→ DNS lookup → api.voting-app.example.com

2. Azure Load Balancer
   └─(Layer 4 LB)──→ Forwards to NGINX Ingress Controller

3. NGINX Ingress Controller
   ├─ Terminates TLS
   ├─ Checks HTTP path (/api/v1/vote)
   └─(HTTP request)──→ Routes to API service

4. Kubernetes Service (API)
   └─(Round-robin)──→ Load balances across 3-10 API pods

5. API Pod Container
   ├─ Process request
   ├─ Query PostgreSQL DB
   └─ Return JSON response

6. Response Path (reversed)
   API → Service → Ingress → Load Balancer → User Browser
```

### Vote Submission Flow

```
Frontend UI (React)
└─ POST /api/v1/vote {"option": "A"}
   └─ NGINX Ingress
      └─ API Service
         └─ API Pod
            ├─ Validate input
            ├─ INSERT INTO votes table (PostgreSQL)
            ├─ Increment counter
            └─ Emit event to message queue
               └─ Worker Pod picks up
                  ├─ Process vote analytics
                  ├─ Generate aggregate statistics
                  └─ Update results cache
```

## Monitoring Data Flow

```
Application Pods
├─ frontend:3000/metrics
├─ api:8080/metrics
└─ worker:8080/metrics
   └─(Prometheus scrape every 30s)──→ Prometheus TSDB

Kubernetes Metrics
├─ Kubelet metrics
├─ Node metrics
└─ Service/Pod metrics
   └─(via kube-state-metrics)──→ Prometheus

Database Metrics
└─ PostgreSQL exporter
   └─(Prometheus scrape)──→ Prometheus

External Availability
└─ Blackbox Exporter (separate VM)
   ├─ Probes: https://api.voting-app.example.com/health (5min)
   ├─ Probes: https://voting-app.example.com (10min)
   └─(Prometheus scrape)──→ Prometheus

      ┌───────────────────────┐
      │   Prometheus TSDB     │
      │  (15-day retention)   │
      └───────────────────────┘
             │       │
             │       └─→ Alert Evaluation (30s interval)
             │           └─→ AlertManager
             │               ├─ Slack notification
             │               └─ PagerDuty incident
             │
             └─→ Grafana Dashboard Queries
                 ├─ Real-time graphs
                 ├─ Alerting dashboard
                 └─ Availability metrics
```

## Disaster Recovery

### Data Backup Strategy

**PostgreSQL Backups** (built-in):
- Automated daily snapshots
- 7-day retention
- Geo-redundant (if HA enabled)

**Application State**:
- Stateless services (no node-local persistence)
- All state in PostgreSQL
- Easy horizontal scaling

**Container Images**:
- ACR retention: All published images
- Rollback: Change image tag in Helm values

### Failure Scenarios

| Failure | Impact | Recovery |
|---------|--------|----------|
| Pod crash | 1-2 replicas down | Kubelet restarts pod (30s) |
| Node failure | ~1/3 pods down | Pods scheduled to other nodes (5min) |
| AZ outage | Potential node loss | Kubernetes reschedules to remaining AZs |
| DB failure | Application unavailable | Azure automatic failover (1-5min) or manual restore |
| Network partition | Ingress unreachable | Azure LB health check reroutes (30s) |

### Recovery Objectives

| Objective | Target | Method |
|-----------|--------|--------|
| RTO (Recovery Time) | < 5 minutes | Kubernetes auto-restart + Azure LB |
| RPO (Recovery Point) | < 1 day | PostgreSQL automated backups |
| MTTR (Mean Time To Repair) | 15 min | Monitoring alerts + runbooks |

## Security Architecture

### Network Security

**Public Exposure**:
- Only NGINX Ingress Controller exposed (via LoadBalancer)
- All pods in private VNet (no public IPs)

**Internal Communication**:
- Pod-to-Pod via Kubernetes DNS
- Pod-to-DB via private VNet
- No internet access (except outbound for updates)

### Pod Security

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
```

**Benefits**:
- Apps can't run as root
- Filesystem immutable (prevents tampering)
- No privilege escalation possible

### Secret Management

**Sensitive Data** (never in Helm values):
- Database credentials → Kubernetes Secrets / Azure Key Vault
- API keys → Azure Key Vault
- SSL certificates → TLS Secret resources

## Scalability & Performance

### Horizontal Scaling

**Frontend** (UI):
- Min: 2 replicas (availability)
- Target: 3-5 replicas (load distribution)
- Max: 5 replicas (cost control)
- Metric: CPU utilization 70%

**API** (Business logic):
- Min: 3 replicas (availability)
- Target: 5-10 replicas (request throughput)
- Max: 10 replicas (cost control)
- Metric: CPU utilization 70%, RPS 100+

**Worker** (Async jobs):
- Min: 1 replica
- Target: 1-5 replicas
- Max: 5 replicas
- Metric: Queue depth, CPU utilization 75%

### Vertical Scaling

**Resource Limits**:
```yaml
Frontend:
  Requests: 50m CPU, 128Mi memory
  Limits: 200m CPU, 256Mi memory

API:
  Requests: 100m CPU, 256Mi memory
  Limits: 500m CPU, 512Mi memory

Worker:
  Requests: 100m CPU, 256Mi memory
  Limits: 500m CPU, 512Mi memory
```

### Performance Characteristics

- **Frontend**: 1 pod = ~100 req/sec (static assets cached)
- **API**: 1 pod = ~50 req/sec (database bound)
- **Worker**: 1 pod = ~100 jobs/sec (background processing)

Adjust based on profiling and load tests.

## Cost Optimization

**Infrastructure**:
- Free-tier AKS (master nodes at no cost)
- Standard_DS2_v2 nodes (~$0.083/hour/node)
- PostgreSQL B_Standard_B1ms (~$15/month)
- ACR Standard (~$5/month)

**Recommendations**:
- Use dev environment for testing
- Schedule non-prod resources to turn off nights/weekends
- Consider spot instances for worker nodes (20-80% savings)

---

**Next**: See [CONFIG.md](CONFIG.md) for detailed configuration reference.
