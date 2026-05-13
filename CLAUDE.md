# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Spring Boot 3.3.5 user management REST API that serves as a DevOps coding challenge. The Java application is already implemented — the DevOps layer (Dockerfile, Helm, Terraform, CI/CD, observability) has been added on top.

## Commands

```bash
# Build (produces fat JAR in target/)
./mvnw clean package

# Run locally (requires MySQL at localhost:3306)
./mvnw spring-boot:run

# Run tests
./mvnw test

# Run a single test class
./mvnw test -Dtest=CrewmeisterChallengeApplicationTests

# Validate Helm chart
helm lint ./charts/crewmeister-challenge
helm template ./charts/crewmeister-challenge

# Bootstrap remote state (run ONCE before first apply)
bash scripts/bootstrap-tfstate.sh

# Deploy dev infrastructure (set env vars first — see Infrastructure section)
cd terragrunt/dev && terragrunt run-all apply

# Tear down dev infrastructure
cd terragrunt/dev && terragrunt run-all destroy
```

## Architecture

### Application (Java)

Standard Spring Boot MVC layering — Controller → Repository → MySQL via JPA:

- **`UserController`** — `GET /user?id={id}` returns greeting string; `POST /user` accepts `{"name":"..."}` and persists a user
- **`User`** — JPA entity with `id` (auto-increment Long) and `name` (String)
- **`UserRepository`** — Spring Data interface; exposes `save()` and `findById()`
- **Flyway** — `V1_0_0__Create_User.sql` creates the `user` table and seeds user "Alice"
- **Spring Actuator** — exposes `health` and `info` endpoints

### Observability (Istio-based — no app code changes)

Observability is provided at the infrastructure layer. **Do not add Micrometer/Prometheus dependencies to the application** — Envoy sidecars handle all metrics collection.

- **Istio** — service mesh with sidecar injection enabled on the `crewmeister` namespace; Envoy captures L7 metrics automatically
- **Jaeger** — distributed tracing; Istio is configured to export traces to Jaeger collector at `jaeger-collector.observability.svc.cluster.local:9411`
- **kube-prometheus-stack** — Prometheus scrapes Istio/Envoy metrics; Grafana for dashboards

### Infrastructure (Terraform + Terragrunt)

Terraform code lives in reusable modules under `terraform/modules/`. Terragrunt orchestrates them under `terragrunt/{dev,prod}/`. Remote state is stored in Azure Blob (`crewmeistertfstate` / `tfstate` container, key pattern `{env}/{module}/terraform.tfstate`).

**Modules and apply order:**

```
rg → (networking + keyvault) → appgw → aks → identity → argocd → argocd-apps
```

| Module | Purpose |
|---|---|
| `rg` | Resource group |
| `networking` | VNet, subnets (aks/appgw/gateway), NSGs, public IPs |
| `keyvault` | Key Vault (RBAC mode), self-signed PFX cert, TLS PEM secrets, MySQL password |
| `appgw` | Application Gateway WAF_v2, WAF policy (OWASP 3.2 + Bot Manager), app UAMI |
| `aks` | AKS cluster with AGIC addon, Workload Identity, CSI Secrets Provider |
| `identity` | Federated credential + role assignments (AGIC→AppGW, app→KV, terraform→KV admin) |
| `argocd` | ArgoCD Helm release only (installs CRDs) |
| `argocd-apps` | Root `Application` resource (App-of-Apps pointing to `argocd/apps/`); split from `argocd` so CRDs exist at plan time |
| `vpn` | Point-to-Site VPN gateway — **disabled** (`skip = true`) for now |

**Required environment variables before applying:**

```bash
export ARM_TENANT_ID=$(az account show --query tenantId -o tsv)
export TF_VAR_MYSQL_PASSWORD=<your-password>
```

Provider versions (injected by Terragrunt `generate "versions"` block): `azurerm ~>4.14`, `azuread ~>3.0`, `helm ~>2.17`, `kubernetes ~>2.35`, `tls ~>4.0`, `time ~>0.11`.

All modules use `azurerm 4.x` conventions — the Key Vault attribute is `rbac_authorization_enabled` (not `enable_rbac_authorization`).

**Azure for Students subscription constraints (subscription `37e7ac15`):**

- Only specific regions are permitted by policy. Confirmed working: `austriaeast`. Blocked: `eastus`. `germanywestcentral` allows networking/keyvault/appgw but AKS only permits ARM/confidential SKUs with no quota.
- `austriaeast` does not support WAF `RateLimitRule` custom rules (requires Redis Cache backend) — the `appgw` WAF policy uses only managed rules (OWASP 3.2 + Bot Manager).
- Dev env: `austriaeast`, `Standard_D2_v3`, 2 nodes. Prod env: still `germanywestcentral` (not yet validated).

**Terragrunt mock outputs:** All dependency blocks include `mock_outputs_allowed_terraform_commands = ["validate", "plan", "init", "destroy"]` and `mock_outputs_merge_strategy_with_state = "shallow"` so that `run-all destroy` works even when upstream modules have empty state (e.g. AKS never applied).

**ArgoCD CRD race condition:** The `argocd` module includes a `time_sleep` of 60 s between the Helm release and the `kubernetes_manifest.root_app` to allow ArgoCD CRDs to register before the `Application` resource is created.

### CI/CD (GitHub Actions)

- `ci.yml` — on PR: runs `./mvnw test`, validates Docker build, lints Helm chart
- `cd.yml` — on push to main: builds JAR → pushes image to `ghcr.io` tagged with short SHA → deploys via `helm upgrade --install`

Required GitHub secrets: `AZURE_CREDENTIALS` (service principal JSON) and `MYSQL_PASSWORD`.

## Configuration

All tunable values in `src/main/resources/application.yml` can be overridden via environment variables:

| Env var | Default | Purpose |
|---|---|---|
| `SPRING_DATASOURCE_URL` | `jdbc:mysql://localhost:3306/challenge?createDatabaseIfNotExist=true` | DB URL |
| `SPRING_DATASOURCE_USERNAME` | `root` | DB user |
| `SPRING_DATASOURCE_PASSWORD` | `dev` | DB password |
| `ACTUATOR_ENDPOINTS` | `health,info` | Exposed actuator endpoints |

In Kubernetes, these are injected from the `ConfigMap` and `Secret` created by the Helm chart.
