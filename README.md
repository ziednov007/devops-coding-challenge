# Crewmeister Challenge

## Background

At Crewmeister, our development team is continuously growing. We aim to hire the best educated, motivated, and enthusiastic people in the field who have fun building up Crewmeister in our vision to empower small businesses to thrive in a digital world. For this quest, we are continuously getting new applicants from all over the world. To filter which candidates could be a good fit, we provide our candidates with a coding challenge that we manually review and evaluate.

---

## DevOps Engineer Task

As a DevOps Engineer at Crewmeister, you will be in charge of several challenging tasks in your daily work. One of your core responsibilities will be to ensure that the system is always running smoothly and that the application is deployed successfully to our customers.

In this challenge, you should use DevOps best practices to architect and implement the complete cycle of building, packaging, and deploying a Java application (specified later in this document).

The following are core technologies/tools that should be present in the solution:

- Dockerfile
- Helm Chart
- Terraform to interact with the Kubernetes cluster

You have the flexibility to utilize any cloud provider of your choice to deploy and run the application effectively. Additionally, it should be designed to operate seamlessly on local machines, allowing for a versatile setup that caters to various operational preferences and environments.

## Plus:

- Create a CI Pipeline in Github to automate the application lifecycle
- Add monitoring tools to check the health of the application

---

## Solution

Infrastructure is provisioned via **Terragrunt** orchestrating 9 Terraform modules with remote state in Azure Blob Storage. All in-cluster workloads are managed by **ArgoCD** using an App-of-Apps GitOps pattern — no Helm commands are issued at deploy time after the initial bootstrap. Observability is provided entirely at the infrastructure layer through Istio Envoy sidecars, with metrics collected by Prometheus, logs aggregated by Loki via an OpenTelemetry DaemonSet, and traces collected by Jaeger.

---

## Architecture Overview

```
                        Internet
                           │
                           ▼ HTTPS (TLS terminated at AppGW)
              Azure Application Gateway WAF_v2
                   AGIC — 68.210.96.188
                           │  HTTP (in-cluster)
                           ▼
                 ┌── istio-system ───────────────────────┐
                 │  shared-gateway-istio (ClusterIP)      │
                 │  Kubernetes Gateway API / HTTPRoute    │
                 └──────────────┬────────────────────────┘
            ┌───────────────────┼───────────────────────┐
            ▼                   ▼                       ▼
    ┌── argocd ──┐   ┌── observability ───┐  ┌── crewmeister ──┐
    │  ArgoCD    │   │  Grafana           │  │  Spring Boot app│
    │  (GitOps)  │   │  Prometheus        │  │  MySQL          │
    │            │   │  Loki              │  │  Envoy sidecar  │
    └────────────┘   │  Jaeger            │  └─────────────────┘
                     │  OTEL Collector    │
                     └────────────────────┘

  Domains
    apps.ziednov007.com       → crewmeister-challenge
    argocd.ziednov007.com     → ArgoCD
    monitoring.ziednov007.com → Grafana
    tracing.ziednov007.com    → Jaeger
```

The Azure Application Gateway (AGIC) is the **only** public entry point. It terminates TLS and forwards traffic in-cluster to the Istio shared gateway, which is a **ClusterIP** service — no second LoadBalancer is needed. HTTPRoutes in each namespace route traffic to the appropriate service.

---

## Repository Layout

```
.
├── terraform/modules/              Reusable Terraform modules (one per concern)
│   ├── rg/                         Resource group
│   ├── networking/                 VNet, subnets, NSGs, public IPs
│   ├── keyvault/                   Key Vault (RBAC), MySQL password, TLS cert
│   ├── appgw/                      Application Gateway WAF_v2
│   ├── aks/                        AKS (Workload Identity, CSI, AGIC addon)
│   ├── identity/                   Federated credentials + role assignments
│   ├── argocd/                     ArgoCD Helm release
│   └── argocd-apps/                Root Application resource (App-of-Apps)
├── terragrunt/
│   ├── terragrunt.hcl              Root config — remote state + provider injection
│   ├── _env/dev.hcl                Dev environment variables (region, SKU, node count)
│   └── dev/                        Per-module subfolders wiring dependencies
├── argocd/
│   ├── root-app.yaml               ArgoCD root Application (App-of-Apps entry point)
│   ├── apps/                       One Application manifest per workload
│   ├── crds/                       Vendored Gateway API CRDs (v1.2.1)
│   └── gateway/                    Shared Istio Gateway + HTTPRoutes + AGIC Ingress
├── charts/crewmeister-challenge/   Application Helm chart
├── .github/workflows/
│   ├── ci.yml                      PR gate: test + Docker build (no push) + Helm lint
│   └── cd.yml                      Push-to-main: build → push image → bump tag in git
└── scripts/bootstrap-tfstate.sh   One-time remote state storage account creation
```

---

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Azure CLI | >= 2.50 | https://learn.microsoft.com/en-us/cli/azure/install-azure-cli |
| Terraform | >= 1.9 | https://developer.hashicorp.com/terraform/install |
| Terragrunt | >= 0.55 | https://terragrunt.gruntwork.io/docs/getting-started/install/ |
| Helm | >= 3.14 | https://helm.sh/docs/intro/install/ |
| kubectl | >= 1.28 | https://kubernetes.io/docs/tasks/tools/ |
| Docker | >= 24 | https://docs.docker.com/get-docker/ |
| Java 17 | 17 | https://adoptium.net/ |

---

## Quick Start — Local Development

```bash
# Start MySQL
docker run -d \
  -e MYSQL_ROOT_PASSWORD=dev \
  -e MYSQL_DATABASE=challenge \
  -p 3306:3306 \
  mysql:8

# Run the application
./mvnw spring-boot:run
```

API available at `http://localhost:8080`:
```bash
curl -X POST http://localhost:8080/user -H 'Content-Type: application/json' -d '{"name":"Alice"}'
curl "http://localhost:8080/user?id=1"
curl http://localhost:8080/actuator/health
```

---

## Cloud Deployment (AKS)

### 1. Authenticate with Azure

```bash
az login
az account set --subscription "<your-subscription-id>"
export ARM_TENANT_ID=$(az account show --query tenantId -o tsv)
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
export TF_VAR_MYSQL_PASSWORD="<strong-password>"
```

### 2. Bootstrap remote state (one-time)

```bash
bash scripts/bootstrap-tfstate.sh
```

This creates the Azure Storage account (`crewmeistertfstate`) and blob container (`tfstate`) used by all Terragrunt modules for remote state. The script is idempotent — safe to re-run. Must be completed before the first `terragrunt run-all apply`.

### 3. Provision infrastructure

```bash
cd terragrunt/dev
terragrunt run-all init
terragrunt run-all apply
```

Terragrunt resolves module dependencies automatically in this order:

```
rg → (networking + keyvault) → appgw → aks → identity → argocd → argocd-apps
```

> **Note:** A `vpn/` module exists in the repo (Point-to-Site VPN gateway) but is disabled (`skip = true`) to keep the setup simpler. It can be re-enabled if private cluster access is needed.

### 4. Configure kubeconfig

```bash
az aks get-credentials \
  --resource-group crewmeister-dev-rg \
  --name crewmeister-dev-aks \
  --overwrite-existing
```

### 5. Verify ArgoCD sync

```bash
kubectl get applications -n argocd
```

ArgoCD is bootstrapped by Terraform and auto-syncs from the repository. Sync waves ensure correct ordering: namespaces → cert-manager / istio-base → istiod / external-secrets → observability stack → crewmeister app.

### 6. Configure local DNS

The app domains are not in public DNS — they must resolve to the AGIC public IP. Get the IP:

```bash
az network public-ip show \
  --resource-group crewmeister-dev-rg \
  --name crewmeister-dev-appgw-pip \
  --query ipAddress -o tsv
```

Add the following to `/etc/hosts` (Linux/macOS) or `C:\Windows\System32\drivers\etc\hosts` (Windows):

```
68.210.96.188  apps.ziednov007.com
68.210.96.188  argocd.ziednov007.com
68.210.96.188  monitoring.ziednov007.com
68.210.96.188  tracing.ziednov007.com
```

> The TLS certificate is self-signed. Browsers will show a security warning — accept it, or pass `-k` to curl.

### 7. Tear down

```bash
cd terragrunt/dev
terragrunt run-all destroy
```

---

## CI/CD Pipeline

### CI (`ci.yml`) — Pull request to `main`

1. Checkout code and set up Java 17 (Temurin)
2. Run `./mvnw test` — full test suite must pass
3. Run `docker build` — validates the Dockerfile compiles (image is **not** pushed)
4. Run `helm lint --strict` + `helm template` — validates chart syntax and rendering

### CD (`cd.yml`) — Push to `main`

1. Run `./mvnw clean package -DskipTests` to build the fat JAR
2. Log into GitHub Container Registry (GHCR) and build/push the Docker image tagged with the 7-character commit SHA and `latest`:
   `ghcr.io/zied-boulifi/crewmeister-challenge:<sha>`
3. Commit the updated `image.tag` into `charts/crewmeister-challenge/values.yaml` and push to `main`
4. ArgoCD detects the git change and automatically syncs the Helm release with the new image

The pipeline never calls `helm upgrade` or `kubectl`. It only updates the image tag in the chart values file — ArgoCD reconciles the cluster.

```
Developer → PR → ci.yml (test / lint / build) → merge to main
                        ↓
              cd.yml: build JAR → push image → commit tag update
                        ↓
              ArgoCD detects change → helm upgrade (in-cluster) → rolling deploy
```

### Required GitHub Secrets

| Secret | Purpose | How to create |
|--------|---------|---------------|
| `AZURE_CREDENTIALS` | Service principal for Azure auth | `az ad sp create-for-rbac --name crewmeister-cd --role contributor --scopes /subscriptions/<id>/resourceGroups/crewmeister-dev-rg --sdk-auth` |
| `MYSQL_PASSWORD` | Must match `TF_VAR_MYSQL_PASSWORD` used at provision time | Any strong password |

---

## Known Limitations & Production Readiness

### Local machine constraints

The [Quick Start](#quick-start--local-development) section covers running the Spring Boot application and MySQL locally. Running the **full stack** (AKS, Istio, ArgoCD, and the complete observability suite) locally is not supported — the current development machine does not have sufficient resources to run a local Kubernetes cluster (minikube/kind) with Istio, the service mesh control plane, and five observability components simultaneously. A cloud deployment is the intended path for the complete environment.

### Architecture production readiness — ~80%

The architecture is designed with production principles in mind and covers the core path end-to-end. The remaining ~20% consists of the following known rectifications before it would be fully production-grade:

| Area | Current state | Production rectification |
|---|---|---|
| **Jaeger storage** | In-memory (all-in-one) — data lost on pod restart | Replace with a persistent backend (Elasticsearch or Cassandra) |
| **Loki storage** | No persistence configured | Add Azure Blob Storage backend for long-term log retention |
| **MySQL** | In-cluster single instance (Bitnami chart) | Replace with Azure Database for MySQL (managed, HA, automated backups) |
| **TLS certificate** | Self-signed, generated by Terraform | Replace with a CA-signed cert (e.g. Let's Encrypt via cert-manager) |
| **Autoscaling** | Fixed 2-node pool, no HPA | Add Horizontal Pod Autoscaler + cluster autoscaler node pool |
| **VPN / private access** | Disabled (`skip = true`) | Re-enable for private API server access and remove public cluster endpoint |
| **ArgoCD credentials** | Default initial secret | Rotate admin password and integrate with an SSO provider (Dex/OIDC) |
| **Network policies** | None defined | Add Kubernetes NetworkPolicies to restrict inter-namespace traffic |

---

## Observability

All services are accessible via DNS through AGIC — no `kubectl port-forward` needed:

| Service | URL |
|---------|-----|
| Application | https://apps.ziednov007.com |
| ArgoCD | https://argocd.ziednov007.com |
| Grafana | https://monitoring.ziednov007.com |
| Jaeger | https://tracing.ziednov007.com |

### Stack

| Component | Version | Role |
|-----------|---------|------|
| Istio + Envoy sidecars | 1.23.0 | L7 metrics, 100% trace sampling — zero app instrumentation |
| kube-prometheus-stack | 61.3.0 | Prometheus + Grafana + Alertmanager |
| Loki | 2.9.10 | Log aggregation |
| Jaeger (all-in-one, in-memory) | 3.3.1 chart | Distributed tracing |
| OpenTelemetry Collector | 0.127.0 | DaemonSet; filelog → Loki, OTLP → Jaeger |

No instrumentation libraries are added to the application. Envoy sidecars capture all L7 metrics automatically. The OTEL Collector DaemonSet reads pod log files from `/var/log/pods` and ships them to Loki.

### First-time login credentials

**ArgoCD** — retrieve the auto-generated initial admin password:
```bash
kubectl get secret -n argocd argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d
```
Username: `admin`

**Grafana** — default credentials set by the kube-prometheus-stack chart:
- Username: `admin`
- Password: `prom-operator`

### Secrets Management

- **Azure Key Vault** (RBAC mode) stores the MySQL password and TLS certificate
- **External Secrets Operator** syncs Key Vault entries into Kubernetes Secrets
- **CSI Secrets Provider** additionally mounts secrets as files inside the pod
- The application pod uses **Workload Identity** — no credentials in environment variables

---

## Application Reference

A Spring Boot application that provides a simple user management REST API.

### Technologies

- Java 17
- Spring Boot 3.3.5
- MySQL 8 + Flyway migrations
- Spring Data JPA
- Spring Actuator
- Maven

### API Endpoints

```bash
# Create a user
curl -s -X POST https://apps.ziednov007.com/user \
  -H 'Content-Type: application/json' \
  -d '{"name":"Alice"}'

# Retrieve user by ID
curl -s "https://apps.ziednov007.com/user?id=1"

# Health check
curl -s https://apps.ziednov007.com/actuator/health
```

### Application Changes

The following changes were made to the original challenge application to support the production infrastructure layer:

#### `TraceContextFilter` (new class)
`src/main/java/.../TraceContextFilter.java`

A servlet filter that extracts Istio/B3 trace headers (`x-b3-traceid`, `x-b3-spanid`) from every incoming HTTP request and populates the SLF4J MDC. This allows every log line emitted during a request to carry the active trace and span IDs, enabling log-to-trace correlation in Grafana/Jaeger. The MDC is cleared in a `finally` block to prevent context leakage across threads.

#### Structured logging (`logback-spring.xml`)
`src/main/resources/logback-spring.xml`

A custom Logback configuration that includes `traceId` and `spanId` from the MDC in every log line:
```
2024-01-15T10:23:45.123Z  INFO [...] UserController traceId=abc123 spanId=def456 : POST /user
```
Timestamps are UTC ISO 8601. Falls back to `traceId=none` when no trace context is present (e.g. startup logs).

#### Actuator & Prometheus endpoint (`application.yml`)
`src/main/resources/application.yml`

Spring Actuator is configured to expose `health`, `info`, and `prometheus` endpoints:
```yaml
management.endpoints.web.exposure.include: ${ACTUATOR_ENDPOINTS:health,info,prometheus}
```
The `prometheus` endpoint is consumed by Prometheus (via Istio/Envoy — no Micrometer scrape is configured; this endpoint is available as a fallback). The exposed endpoints are environment-configurable via `ACTUATOR_ENDPOINTS`.

#### Environment-driven datasource configuration (`application.yml`)
All connection parameters are injected from environment variables with local-dev defaults:

| Env var | Default | Purpose |
|---------|---------|---------|
| `SPRING_DATASOURCE_URL` | `jdbc:mysql://localhost:3306/challenge?createDatabaseIfNotExist=true` | DB URL |
| `SPRING_DATASOURCE_USERNAME` | `root` | DB user |
| `SPRING_DATASOURCE_PASSWORD` | `dev` | DB password |
| `ACTUATOR_ENDPOINTS` | `health,info,prometheus` | Exposed actuator endpoints |

In Kubernetes these are injected from the `ConfigMap` and `Secret` created by the Helm chart (or from Azure Key Vault via ESO).

#### Multi-stage Docker build (`Dockerfile`)
A two-stage build separates build-time and runtime dependencies:
- **Stage 1** (`maven:3.9.9-eclipse-temurin-17`): runs `dependency:go-offline` first (layer-cached), then compiles the fat JAR
- **Stage 2** (`eclipse-temurin:17-jre-alpine`): copies only the JAR into a minimal Alpine JRE image, keeping the final image small and free of build tooling
