# Operations & Runbooks

Operational procedures, troubleshooting guides, and runbooks for maintaining the voting application.

## Table of Contents

1. [Daily Operations](#daily-operations)
2. [Monitoring & Alerting](#monitoring--alerting)
3. [Scaling & Performance](#scaling--performance)
4. [Disaster Recovery](#disaster-recovery)
5. [Troubleshooting](#troubleshooting)
6. [Incident Response](#incident-response)

## Daily Operations

### Health Checks

**Automated Monitoring** (via Prometheus + Grafana):
- Check Grafana dashboards for anomalies
- Review alert notifications
- Monitor SLO achievement

**Manual Health Checks** (weekly):

```bash
# 1. Check cluster health
kubectl cluster-info && kubectl get nodes

# 2. Check pod status
kubectl get pods -n default
kubectl get pods -n monitoring

# 3. Check resource usage
kubectl top nodes
kubectl top pods -n default

# 4. Check services
kubectl get svc -n default
kubectl get svc -n ingress-nginx

# 5. Test API endpoint
curl https://api.voting-app.example.com/api/v1/health

# 6. Check database
kubectl exec -it <api-pod> -- \
    psql -h <db-host> -U <user> -d votingapp -c "SELECT COUNT(*) FROM votes;"
```

### Backup Verification

```bash
# PostgreSQL automatic backups (Azure-managed)
# Verify in Azure Portal:
# - Resource Group → PostgreSQL server → Backups

# Application state:
# All state in PostgreSQL, so DB backup = full backup
```

### Log Review

```bash
# API logs
kubectl logs -f deployment/voting-app-api --all-containers=true

# Frontend logs
kubectl logs -f deployment/voting-app-frontend

# Worker logs
kubectl logs -f deployment/voting-app-worker

# Ingress logs
kubectl logs -f deployment/ingress-nginx -n ingress-nginx

# Prometheus logs
kubectl logs -f pod/prometheus-kube-prometheus-prometheus-0 -n monitoring
```

## Monitoring & Alerting

### Key Dashboards

| Dashboard | Purpose | Check |
|-----------|---------|--------|
| Application Overview | Service health | RPS, errors, latency |
| API Gateway | Traffic & routing | HTTP codes, upstream response times |
| Infrastructure | Cluster resources | Node CPU/Memory, PVC usage |
| Database | PostgreSQL health | Connections, query performance |
| Availability | SLO tracking | Uptime %, error budget |

### Important Alerts

```
HighErrorRate (5min @ >5% errors)
→ Indicates application bug or database issue
→ Action: Check logs, identify failing endpoint

HighLatency (5min @ p95 > 500ms)
→ Indicates performance degradation
→ Action: Check database queries, scale API replicas

DatabaseDown (1min)
→ Critical - application unavailable
→ Action: Check DB service, verify connectivity

PodCrashLooping (15min)
→ Indicates configuration or resource limitation
→ Action: Check logs, increase memory/CPU limits

NodeMemoryPressure (5min)
→ Cluster running out of memory
→ Action: Scale down non-critical workloads or add nodes
```

### Alert Silence (Emergency)

```bash
# Temporarily silence alert (e.g., during maintenance)
kubectl exec -it alertmanager-0 -n monitoring -- \
    amtool silence add \
    --duration=1h \
    --comment="Maintenance window" \
    HighErrorRate
```

## Scaling & Performance

### Horizontal Autoscaling

**Current Configuration**:
- Frontend: min=2, max=5, trigger=70% CPU
- API: min=3, max=10, trigger=70% CPU
- Worker: min=1, max=5, trigger=75% CPU

**Monitor HPA**:
```bash
kubectl get hpa -w

NAME                    REFERENCE                    TARGETS          MINPODS   MAXPODS
voting-app-frontend    Deployment/voting-app-frontend   62%/70%     2         5
voting-app-api         Deployment/voting-app-api        48%/70%     3         10
voting-app-worker      Deployment/voting-app-worker     40%/75%     1         5
```

### Manual Scaling

```bash
# Scale API to handle spike
kubectl scale deployment voting-app-api --replicas=8

# Scale down after spike
kubectl scale deployment voting-app-api --replicas=5

# Check status
kubectl describe deployment voting-app-api | grep Replicas
```

### Performance Optimization

**If high latency**:

1. Check database performance:
   ```bash
   # Slow queries
   kubectl logs <api-pod> | grep "slow"
   
   # Connection pool exhaustion?
   psql -h <db-host> -c "SELECT count(*) FROM pg_stat_activity;"
   ```

2. Scale API instances:
   ```bash
   kubectl scale deployment voting-app-api --replicas=7
   ```

3. Review Grafana for bottleneck

**If high CPU usage**:

1. Check what's consuming CPU:
   ```bash
   kubectl top pod -n default | sort -k3 -r
   ```

2. Allocate more CPU or optimize code

3. Adjust HPA target:
   ```bash
   helm upgrade api helm-charts/services/api \
       --set autoscaling.targetCPUUtilizationPercentage=60
   ```

## Disaster Recovery

### Database Failure

**Symptom**: API pods can't connect to database

```bash
# 1. Verify database is down
kubectl exec <api-pod> -- \
    psql -h <db-host> -U <user> -d votingapp -c "SELECT 1" 2>&1 | grep -i "error"

# 2. Check Azure portal for DB health
# Azure Portal → PostgreSQL server → Connection Security

# 3. Check application logs
kubectl logs <api-pod> | grep -i "database\|connection"

# 4a. Failover to replica (if HA enabled)
# Azure Portal → PostgreSQL server → High Availability

# 4b. Restore from backup (if needed)
# Azure Portal → PostgreSQL server → Restore

# 5. If crash due to bad data, restore snapshot
terraform destroy -target=azurerm_postgresql_flexible_server.db
terraform apply -target=azurerm_postgresql_flexible_server.db  # Restores from backup

# 6. Verify data integrity
kubectl exec <api-pod> -- psql -h <db-host> -c "SELECT COUNT(*) FROM votes;"
```

### Node Failure

**Symptom**: Some pods not running

```bash
# 1. Check node status
kubectl get nodes
kubectl describe node <node-name>

# 2. Kubernetes automatically reschedules pods
# Watch redeployment
kubectl get pods -w

# 3. If issue persists, drain and remove node
kubectl drain <node-name> --ignore-daemonsets
kubectl delete node <node-name>

# 4. Cluster will autoscale to replace node
# Or manually: kubectl scale deployment <deploy> --replicas=N
```

### Full Cluster Recovery

```bash
# 1. Verify Terraform state
cd terraform
terraform state list

# 2. If needed, reinitialize cluster
terraform destroy -target azurerm_kubernetes_cluster.aks
terraform apply -target azurerm_kubernetes_cluster.aks

# 3. Reapply Helm charts
helm repo update
helm upgrade --install <releases>

# 4. Restore database (from backup)
# Azure CLI or Portal

# 5. Verify all services running
kubectl get all -n default
kubectl get all -n monitoring
```

## Troubleshooting

### Pod Stuck in Pending

```bash
# Causes: Insufficient resources, image pull error, PVC pending

# Check pod details
kubectl describe pod <pod-name>

# Check resource availability
kubectl describe nodes

# Solution: If resource constrained
az aks scale --resource-group <rg> --name <aks> --node-count 5
```

### Pod High Memory Usage

```bash
# Monitor memory
kubectl top pod <pod-name> --containers

# Limits exceeded?
kubectl describe pod <pod-name> | grep -A 3 "Limits"

# Check logs for memory leaks
kubectl logs <pod-name> | grep -i "oom\|memory"

# Solution: Increase limits in Helm values
helm upgrade api helm-charts/services/api \
    --set resources.limits.memory=1Gi
```

### API Response Timeout

```bash
# 1. Check if pods are running
kubectl get pods | grep api

# 2. Check pod logs
kubectl logs -f deployment/voting-app-api

# 3. Check ingress routing
kubectl describe ingress voting-app

# 4. Test direct pod endpoint
kubectl port-forward svc/voting-app-api 8080:8080
curl http://localhost:8080/api/v1/health

# 5. Check database connectivity
kubectl exec <api-pod> -- \
    psql -h <db-host> -U <user> -d votingapp -c "SELECT 1"

# 6. Scale API replicas
kubectl scale deployment voting-app-api --replicas=5
```

### TLS Certificate Error

```bash
# Check certificate
kubectl get secret voting-app-tls

# View details
kubectl describe secret voting-app-tls

# If expired or invalid, renew
# Option 1: Let's Encrypt (auto-renewal via cert-manager)
kubectl get certificate

# Option 2: Manual certificate
kubectl delete secret voting-app-tls
kubectl create secret tls voting-app-tls \
    --cert=path/to/updated-cert.pem \
    --key=path/to/updated-key.pem
```

### Prometheus Not Scraping Metrics

```bash
# Check targets
curl http://localhost:9090/api/v1/targets

# Check for errors
kubectl logs -f pod/prometheus-kube-prometheus-prometheus-0 -n monitoring

# Verify pod has annotation
kubectl get pods -o yaml | grep -A 5 "prometheus.io/scrape"

# Add annotation if missing
kubectl patch deployment voting-app-api \
    --patch='{"spec":{"template":{"metadata":{"annotations":{"prometheus.io/scrape":"true"}}}}}'
```

## Incident Response

### Alert Firing - High Error Rate

**Step 1: Confirm Issue**
```bash
# Check real users affected
curl https://api.voting-app.example.com/api/v1/health

# Check logs for error pattern
kubectl logs deployment/voting-app-api | tail -20
```

**Step 2: Root Cause**
```bash
# Database connectivity?
# Check: DATABASE_HOST, DATABASE_USER, password

# Application bug?
# Check: Recent deployments, recent commits

# Invalid requests?
# Check: API input validation
```

**Step 3: Mitigation**

- **If database issue**: Check DB logs, verify connectivity, failover if needed
- **If app bug**: Rollback recent deployment:
  ```bash
  helm history api   # See previous versions
  helm rollback api 2  # Rollback to version 2
  ```
- **If traffic spike**: Scale API replicas:
  ```bash
  kubectl scale deployment voting-app-api --replicas=8
  ```

**Step 4: Communication**
- Update status page
- Notify stakeholders on Slack/email
- Document in incident log

### Alert Firing - Pod CrashLooping

**Step 1: Check Pod Status**
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name> --previous  # Logs from before crash
```

**Step 2: Common Causes**

- **OOMKilled**: Memory limit too low
  ```bash
  helm upgrade api helm-charts/services/api \
      --set resources.limits.memory=1Gi
  ```

- **Liveness probe failing**: Service not healthy
  ```bash
  # Temporarily increase initialDelaySeconds
  helm upgrade api helm-charts/services/api \
      --set livenessProbe.initialDelaySeconds=60
  ```

- **Config error**: Check ConfigMap/Secrets
  ```bash
  kubectl describe configmap voting-app-api
  kubectl get secret
  ```

**Step 3: Resolution**
```bash
# Fix issue and redeploy
helm upgrade api helm-charts/services/api \
    --set image.tag=v1.0.1 \
    --set <fix-parameter>=<value>
```

### Database Connection Timeout

**Symptoms**: API requests timeout, can't connect to DB

**Investigation**:
```bash
# 1. Check if DB is running
psql -h <db-host> -U <user> -d votingapp -c "SELECT 1"

# 2. Check network connectivity
kubectl run -it --rm debug --image=busybox --restart=Never -- \
    telnet <db-host> 5432

# 3. Check API pod logs
kubectl logs deployment/voting-app-api | grep -i "database\|connection\|timeout"

# 4. Check if pods can reach DB
kubectl exec <api-pod> -- getent hosts <db-host>
```

**Solutions**:
- **DB down**: Restart DB, check backups
- **Network issue**: Check NSGs, VNet, firewall rules
- **Connection pool exhausted**: Reduce connection timeout, scale down clients
- **Bad credentials**: Verify DATABASE_USER, DATABASE_PASSWORD secrets

---

**Emergency Contact**: On-call engineer pager (configured in AlertManager)

---

**Version**: 1.0  
**Last Updated**: 2026-03-29
