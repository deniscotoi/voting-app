# Monitoring & Observability Stack

Complete observability solution for the three-tier voting application with metrics collection, tracing, and visualization.

## Components

### Prometheus
- Metrics collection and time-series database
- Scrape targets: Applications, API Gateway, Persistence layer, Infrastructure
- Alert rule evaluation
- 15-day data retention

### Grafana
- Visualization and dashboarding
- Data source: Prometheus
- Pre-configured dashboards:
  - System/Infrastructure metrics
  - API Gateway performance
  - Application availability
  - Database performance
  - Black-box monitoring

### OpenTelemetry Collector
- Metrics and trace aggregation
- Receives data from applications
- Forwards to Prometheus and tracing backends

## Directory Structure

```
monitoring/
├── README.md                    # This file
├── prometheus/
│   ├── values.yaml            # Helm values for Prometheus
│   ├── prometheus.yml         # Scrape configuration
│   └── alerts.yml             # Alert rules
├── grafana/
│   ├── values.yaml            # Helm values for Grafana
│   └── dashboards/
│       ├── application.json
│       ├── api-gateway.json
│       ├── database.json
│       ├── availability.json
│       └── blackbox.json
├── otel-collector/
│   └── values.yaml            # Helm values for OTEL Collector
└── blackbox/
    ├── values.yaml            # Helm values for Blackbox Exporter
    └── targets.yml            # Blackbox probe targets
```

## Quick Start

### 1. Add Helm Repositories

```bash
# Prometheus Community Helm charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts

helm repo update
```

### 2. Create Namespace

```bash
kubectl create namespace monitoring
```

### 3. Deploy Prometheus

```bash
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values monitoring/prometheus/values.yaml
```

### 4. Deploy Grafana

```bash
helm install grafana grafana/grafana \
  --namespace monitoring \
  --values monitoring/grafana/values.yaml
```

### 5. Deploy OpenTelemetry Collector

```bash
helm install otel-collector open-telemetry/opentelemetry-collector \
  --namespace monitoring \
  --values monitoring/otel-collector/values.yaml
```

### 6. Access Dashboards

```bash
# Port-forward Grafana
kubectl port-forward -n monitoring svc/grafana 3000:80

# Port-forward Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```

- **Grafana**: http://localhost:3000 (default admin/prom-operator)
- **Prometheus**: http://localhost:9090

## Monitoring Stack Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  Application Tier                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │   Frontend   │  │     API      │  │    Worker    │       │
│  │   (metrics)  │  │   (metrics)  │  │   (metrics)  │       │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘       │
│         │                 │                 │               │
└─────────┼─────────────────┼─────────────────┼───────────────┘
          │                 │                 │
          └─────────────────┼─────────────────┘
                            │
                            ▼
                ┌──────────────────────┐
                │  Prometheus Scraper  │
                │   (pulls metrics)    │
                └──────────┬───────────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
        ▼                  ▼                  ▼
┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│ Prometheus   │   │ OTEL Coll.   │   │  Grafana DB  │
│  (TSDB)      │   │  (aggregator)│   │  (dashboard) │
└──────┬───────┘   └──────┬───────┘   └──────────────┘
       │                  │
       └──────────┬───────┘
                  │
                  ▼
          ┌────────────────┐
          │  Grafana UI    │
          │  Dashboards    │
          └────────────────┘
```

## Key Metrics Collected

### Application Metrics
- Request rate (RPS)
- Request latency (p50, p95, p99)
- Error rate (5xx responses)
- Custom business metrics

### Infrastructure Metrics
- Pod CPU/Memory usage
- Node resource utilization
- PVC usage
- Network I/O

### Database Metrics
- Connection count
- Query performance
- Replication lag
- Backup status

### API Gateway Metrics
- HTTP status distribution
- Request path distribution
- Upstream response times
- TLS handshake metrics

## Alert Rules

See `prometheus/alerts.yml` for:
- High error rate (>5% 5xx errors)
- High latency (p95 > 500ms)
- Pod crash loops
- Persistent volume space warnings
- Database connection warnings

## Grafana Dashboards

Pre-configured dashboards for:
1. **Application Overview** - Service health, endpoints, latency
2. **API Gateway** - Status distribution, latency trends
3. **Database** - Connections, query performance, replication
4. **Infrastructure** - Cluster resources, node health
5. **Availability** - Black-box uptime, SLA tracking

## Persistence

All monitoring data stored in Prometheus for 15 days by default. Configure retention in `prometheus/values.yaml`:

```yaml
prometheus:
  prometheusSpec:
    retention: 15d  # Adjust as needed
```

## Troubleshooting

### Prometheus not scraping targets
```bash
# Check scrape targets
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Visit http://localhost:9090/targets
```

### Grafana can't reach Prometheus
```bash
# Verify Prometheus service DNS
kubectl exec -n monitoring <grafana-pod> -- nslookup prometheus-kube-prometheus-prometheus.monitoring.svc
```

### OTEL Collector not receiving data
```bash
# Check logs
kubectl logs -n monitoring <otel-collector-pod>

# Verify applications are sending to: http://otel-collector:4317 (gRPC)
```

## Next Steps

1. Deploy application Helm charts (Step 4)
2. Configure application metric endpoints
3. Create custom dashboards for business metrics
4. Set up alert notifications (Slack, PagerDuty, etc.)

---

**Version**: 1.0  
**Last Updated**: 2026-03-29
