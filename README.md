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

## Important Points:

- At Crewmeister, we value creativity and pushing for better. You are encouraged to expand the solution as you find fit. To do so, you must ensure high-quality documentation and that the base solution is correctly executed.
- All the tools used must be publicly accessible or explicitly documented on how to authenticate.
- All the tools must be free to use.

## Submission:
- Provide the link to your GitHub repository in the Greenhouse submission form.
- Submit your completed project via the Greenhouse link in the email received from the Recruitment Manager.

---

## Solution

### Architecture Overview

```
GitHub Actions CI/CD
        │
        ▼
ghcr.io (Docker image)
        │
        ▼
AKS (Azure Kubernetes Service)
 ├── istio-system
 │   ├── Istio (service mesh + Envoy sidecar metrics)
 │   └── Istio Ingress Gateway
 ├── observability
 │   ├── Jaeger (distributed tracing)
 │   ├── Prometheus (metrics from Istio/Envoy)
 │   └── Grafana (dashboards)
 └── crewmeister (app namespace — Istio injection enabled)
     ├── MySQL (bitnami/mysql)
     └── crewmeister-challenge (Spring Boot app)
```

Observability is provided entirely at the **infrastructure layer** via Istio — no instrumentation libraries are added to the application code. Envoy sidecars automatically capture L7 metrics (request rate, latency, error rate) which Prometheus scrapes, while Jaeger collects distributed traces exported by Istio.

---

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Azure CLI | >= 2.50 | https://learn.microsoft.com/en-us/cli/azure/install-azure-cli |
| Terraform | >= 1.5 | https://developer.hashicorp.com/terraform/install |
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
```

### 2. Provision infrastructure + deploy all services

```bash
cd terraform
terraform init
terraform apply \
  -var="mysql_password=<strong-password>" \
  -var="app_image_tag=latest"
```

This provisions:
- Azure Resource Group
- AKS cluster (1 × Standard_B2s node)
- Istio service mesh (base + istiod + ingress gateway)
- Jaeger (all-in-one, in-memory)
- kube-prometheus-stack (Prometheus + Grafana + Alertmanager)
- MySQL (bitnami/mysql)
- crewmeister-challenge application

### 3. Access the application

```bash
# Get AKS credentials
terraform output -raw kube_config > ~/.kube/config

# Get ingress gateway external IP
kubectl get svc -n istio-system istio-ingressgateway

# Access Grafana
kubectl port-forward -n observability svc/kube-prometheus-stack-grafana 3000:80
# Open http://localhost:3000 (admin / admin)

# Access Jaeger UI
kubectl port-forward -n observability svc/jaeger-query 16686:16686
# Open http://localhost:16686
```

---

## CI/CD Pipeline (GitHub Actions)

Two workflows are defined in `.github/workflows/`:

| Workflow | Trigger | Steps |
|----------|---------|-------|
| `ci.yml` | Pull Request → main | Test, Docker build (validate), Helm lint |
| `cd.yml` | Push → main | Build JAR → push image to ghcr.io → deploy via Helm to AKS |

### Required GitHub Secrets

| Secret | How to set |
|--------|-----------|
| `AZURE_CREDENTIALS` | `az ad sp create-for-rbac --name crewmeister-cd --role contributor --scopes /subscriptions/<id>/resourceGroups/crewmeister-rg --sdk-auth` |
| `MYSQL_PASSWORD` | Any strong password matching the one used in Terraform |

---

## Challenge Application

A Spring Boot application that provides a simple user management REST API.

### Technologies Used

- Java 17
- Spring Boot 3.3.5
- MySQL Database
- Flyway Migration
- Maven
- Spring Data JPA
- Spring Actuator

### Pre-requisites

- JDK 17
- MySQL
- Maven

### API Endpoints

#### GET /user

Retrieves a user by ID

#### POST /user

Creates a new user
