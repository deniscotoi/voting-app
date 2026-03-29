# Monitoring & Observability Guide

Complete guide to metrics collection, dashboarding, alerting, and troubleshooting using Prometheus, Grafana, and OpenTelemetry.

## Monitoring Architecture

```
┌─────────────────────────────────────────────────────┐
│               Application Services                   │
│  (Frontend, API, Worker - export metrics @ :8080)   │
└────────────────────┬────────────────────────────────┘
                     │ Scrape every 30s
                     ▼
        ┌────────────────────────┐
        │    Prometheus TSDB     │
        │   (15-day retention)   │
        └────────────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
        ▼                         ▼
   ┌─────────────┐          ┌──────────────┐
   │    Grafana  │          │ AlertManager │
   │ (Dashboard) │          │  (Alerting)  │
   └─────────────┘          └──────────────┘
        │
        └─► Grafana Dashboards (Real-time visualization)
```

## Key Metrics

### Application-Level Metrics

**HTTP Requests:**
```
http_requests_total{service="api", status="200"} 45230
http_request_duration_seconds{service="api", le="0.5"} 42100
```

**Business Metrics:**
```
votes_submitted_total{option="A"} 1023
votes_submitted_total{option="B"} 987
```

### Infrastructure Metrics

**Pod Resources:**
```
container_cpu_usage_seconds{pod="api-xyz"} 12.5
container_memory_usage_bytes{pod="api-xyz"} 268435456
```

**Node Resources:**
```
node_cpu_usage_seconds{node="aks-node-1"} 45.2
node_memory_usage_bytes{node="aks-node-1"} 8589934592
```

### Database Metrics

**PostgreSQL:**
```
pg_stat_activity_count{database="votingapp"} 12
pg_slow_queries 3
pg_replication_lag_bytes 0
```

## Grafana Dashboards

### 1. Application Overview

**Purpose**: Monitor application health and performance

**Panels:**
- Request rate (RPS) by service
- Error rate (5xx) trend
- Request latency (p50, p95, p99)
- Pod restart count
- Deployment replica status

**URL**: http://grafana:3000/d/application-overview

### 2. API Gateway

**Purpose**: Monitor ingress controller and routing

**Panels:**
- HTTP status code distribution (2xx, 3xx, 4xx, 5xx)
- Request latency percentiles
- Upstream service availability
- Request path popularity
- TLS handshake metrics

### 3. Database Performance

**Purpose**: Monitor PostgreSQL health

**Panels:**
- Active connections
- Query speed distribution
- Slow query count (>100ms)
- Replication lag
- Disk usage trend
- Backup status

### 4. Infrastructure

**Purpose**: Monitor Kubernetes cluster resources

**Panels:**
- Node CPU/Memory utilization
- Pod resource usage
- PVC usage trends
- Network I/O
- Disk I/O

### 5. Availability & SLA

**Purpose**: Track uptime and SLO compliance

**Panels:**
- 99.9% SLA achievement percentage
- Black-box probe success rate
- Availability by time range (1h, 24h, 7d, 30d)
- Error budget remaining
- Incidents timeline

## Alert Rules

### Critical Alerts

**HighErrorRate** - Error rate > 5% for 5 min
```
(sum(rate(http_requests_total{status=~"5.."}[5m])) / 
 sum(rate(http_requests_total[5m]))) > 0.05
```
Action: Page on-call engineer immediately

**DatabaseDown** - PostgreSQL unreachable
```
pg_up == 0
```
Action: Critical - check DB service immediately

### Warning Alerts

**HighLatency** - p95 latency > 500ms
```
histogram_quantile(0.95, http_request_duration_seconds) > 0.5
```
Action: Investigate slow queries, increase replicas

**PodCrashLooping** - Pod restarting > 0.1/min
```
rate(kube_pod_container_status_restarts_total[15m]) > 0.1
```
Action: Check pod logs, increase resource limits

**MemoryPressure** - Node low on memory
```
kube_node_status_condition{condition="MemoryPressure",status="true"} == 1
```
Action: Add nodes or scale down pods

## Prometheus Queries

### Request Rate by Service
```promql
sum(rate(http_requests_total[5m])) by (service)
```

### Error Rate Percentage
```promql
(sum(rate(http_requests_total{status=~"5.."}[5m])) / 
 sum(rate(http_requests_total[5m]))) * 100
```

### Latency Percentiles
```promql
# p50
histogram_quantile(0.50, http_request_duration_seconds) 

# p95
histogram_quantile(0.95, http_request_duration_seconds) 

# p99
histogram_quantile(0.99, http_request_duration_seconds)
```

### Availability (successful requests)
```promql
(sum(rate(http_requests_total{status!~"5.."}[5m])) / 
 sum(rate(http_requests_total[5m]))) * 100
```

### Pod Restart Count
```promql
kube_pod_container_status_restarts_total
```

### Node CPU Usage
```promql
100 - (avg by (node) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

### Memory Usage Percentage
```promql
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
```

### Database Connections
```promql
pg_stat_activity_count
```

## Custom Metrics (Application)

Services should expose metrics in Prometheus format at `/metrics`:

```python
# Python example using prometheus_client
from prometheus_client import Counter, Histogram

# Counter: votes submitted
votes_counter = Counter('votes_submitted_total', 
                       'Total votes submitted', 
                       ['option'])

# Histogram: vote processing time
vote_duration = Histogram('vote_processing_seconds', 
                         'Time to process vote')

@app.post('/api/v1/vote')
def submit_vote(option):
    votes_counter.labels(option=option).inc()
    with vote_duration.time():
        # Process vote
        pass
```

## SLO & SLI Definition

### Service Level Objectives (SLO)

**Availability SLO**: 99.9% uptime per month
```
(successful_requests / total_requests) * 100 >= 99.9%
```

**Latency SLO**: p95 response time < 500ms
```
histogram_quantile(0.95, request_duration) <= 0.5s
```

**Error SLO**: Error rate < 0.1%
```
(error_requests / total_requests) * 100 < 0.1%
```

### Service Level Indicators (SLI)

**Availability SLI** (measured):
```promql
(sum(rate(http_requests_total{status!~"5.."}[5m])) / 
 sum(rate(http_requests_total[5m]))) * 100
```

**Latency SLI** (measured):
```promql
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```

**Error SLI** (measured):
```promql
(sum(rate(http_requests_total{status=~"5.."}[5m])) / 
 sum(rate(http_requests_total[5m]))) * 100
```

### Error Budget

**Monthly error budget** (for 99.9% SLO):
- Total minutes: 43,200 (30 days × 24 h × 60 min)
- Allowed downtime: 43,200 × (1 - 0.999) = 43.2 minutes
- **Budget**: 43 minutes of downtime per month

Track remaining budget:
```promql
(1 - (sum(increase(http_requests_total{status!~"5.."}[30d])) / 
       sum(increase(http_requests_total[30d])))) * 43200 minutes
```

## Black-Box Monitoring (External)

External availability checks from outside the cluster:

### Targets Monitored

1. **API Health Endpoint**
   - URL: `https://api.voting-app.example.com/api/v1/health`
   - Interval: 5 minutes
   - Expected: HTTP 200

2. **Frontend Homepage**
   - URL: `https://voting-app.example.com/`
   - Interval: 10 minutes
   - Expected: HTTP 200

3. **Database Port**
   - Target: `tcp://voting-app-prod-pg.database.windows.net:5432`
   - Interval: 15 minutes
   - Expected: TCP connect success

### Probe Results

```promql
# Success rate
probe_success{job="voting-app-api"}

# Latency
probe_duration_seconds{job="voting-app-api"}

# HTTP status
probe_http_status_code{instance="api.voting-app.example.com"}
```

## Accessing Monitoring Systems

### Prometheus

```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# http://localhost:9090
```

Access targets: http://localhost:9090/targets
Access alerts: http://localhost:9090/alerts

### Grafana

```bash
kubectl port-forward -n monitoring svc/grafana 3000:80
# http://localhost:3000
# Default: admin / prom-operator
```

### Alert Manager

```bash
kubectl port-forward -n monitoring svc/alertmanager 9093:9093
# http://localhost:9093
```

View active alerts and silences.

## Troubleshooting

### Prometheus not scraping

**Check targets:**
```bash
curl http://localhost:9090/api/v1/targets
```

**Check service discovery:**
```
kubectl -n monitoring logs pod/prometheus-kube-prometheus-prometheus-0 | grep "service discovery"
```

### Grafana can't reach Prometheus

**Test DNS resolution:**
```bash
kubectl exec -it deployment/grafana -n monitoring -- \
    nslookup prometheus-kube-prometheus-prometheus.monitoring.svc
```

### Missing metrics

**Verify pod annotation labels:**
```bash
kubectl get pods -o yaml | grep -A 2 "prometheus.io"
```

**Manually test scrape:**
```bash
kubectl exec -it deployment/api -- curl http://localhost:8080/metrics
```

### High cardinality problem

Check for unbounded label values:
```promql
count(count by (__name__) (http_requests_total))
```

Too many unique label combinations can exhaust memory.

## Best Practices

✅ **Always include resource requests/limits** - Helps Prometheus estimate health
✅ **Use consistent label names** - Makes queries easier
✅ **Avoid high-cardinality labels** - Don't use request IDs, user IDs as labels
✅ **Set alert thresholds based on SLO** - Not arbitrary values
✅ **Test alerts regularly** - Use `amtool` to test AlertManager
✅ **Document dashboard interpretation** - Help team understand metrics
✅ **Retain metrics appropriately** - 15 days for operational, 90 days for trending

---

**Next**: See [CONFIG.md](CONFIG.md) for configuration reference.
