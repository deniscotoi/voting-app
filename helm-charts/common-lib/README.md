# Common Library Chart - Reusable templates for all services

## Usage

In service charts, include this library:

```yaml
dependencies:
  - name: common-lib
    version: 1.0.0
    repository: file://../common-lib
```

Then use templates in values:

```yaml
replicaCount: 3
image:
  repository: myregistry.azurecr.io/voting-app
  tag: "1.0.0"
resources:
  requests:
    cpu: 100m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

## Available Templates

- `deployment.yaml` - Deployment with pod security, health checks, resource limits
- `service.yaml` - Service configuration for internal/external exposure
- `configmap.yaml` - Environment configuration
- `secret.yaml` - Sensitive data (credentials, keys)
- `ingress.yaml` - Ingress rules
- `hpa.yaml` - Horizontal Pod Autoscaler
- `pdb.yaml` - Pod Disruption Budget
- `serviceaccount.yaml` - RBAC Service Account

## Values Hierarchy

1. Service chart `values.yaml`
2. Environment overrides (`-f values-prod.yaml`)
3. Common library defaults
