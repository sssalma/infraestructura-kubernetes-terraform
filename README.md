# GSX Práctica 2: GreenDevCorp Infrastructure

Infraestructura de GreenDevCorp usando Docker, Kubernetes y Terraform.

---
## ⚠️ 
**Se implementa:**
-  Docker: 2 imágenes (nginx, simple-app)
-  Kubernetes: 2 pods, 2 services, 3 network policies
-  **Terraform: IaC completo que despliega todo** ← Week 11+13
-  Networking & Security: NetworkPolicies activas

**No se implementa pero se documenta CIDR Plan:**
- 📄 CIDR Plan (múltiples subnets) - Propuesta

---

## Architecture
nginx Pod (1/1 Running) 
─→ NodePort 30080
simple-app Pod (1/1 Running)

Services:

nginx: NodePort (acceso externo)
simple-app: ClusterIP (acceso interno)

SecurityNetwork Policies:

deny-all (base)
allow-nginx (puede hablar con app)
allow-simple-app (puede recibir de nginx)

ConfigMap: app-config (variables de entorno)

---

## Getting Started
### Prerequisites

```bash
docker --version          #  Needed
minikube version          #  Needed
kubectl version           #  Needed
terraform --version       #  Used for IaC
```

### Deploy (usando Terraform = IaC)

```bash
cd terraform/
terraform apply
# Esto despliega TODO automáticamente
```

### What Terraform Deploys
 kubernetes_config_map.app_config
 kubernetes_deployment.nginx
 kubernetes_deployment.simple_app
 kubernetes_service.nginx (NodePort)
 kubernetes_service.simple_app (ClusterIP)
 kubernetes_network_policy.deny_all
 kubernetes_network_policy.allow_nginx
 kubernetes_network_policy.allow_simple_app

---

## Project Structure
gsx_P2/
├── week_8/                 # Docker
├── week_9/                 # Docker Compose
├── week_10/                # Kubernetes YAML (no usado en deploy)
├── week_11/                # CI/CD
├── week_12/                # Network & Security (mostly conceptual)
│
├── week_13/                #  Testing + Full Documentation
│   └── challenge_c/        # ← Complete docs here
│   └── challenge_b/        # ← Integration Test
├── terraform/              
│   ├── main.tf             # Deployments, services
│   ├── network-policies.tf # NetworkPolicies
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfstate
│
└── README.md (this file)

## How It Works

1. **Terraform reads state** from `terraform/`
2. **Terraform connects to Kubernetes** (via kubectl config)
3. **Terraform creates resources** (8 total)
4. **Kubernetes runs everything** (IaC → actual infrastructure)

```bash
terraform apply
  ↓
Creates 8 Kubernetes resources
  ↓
Pods start, services expose them
  ↓
NetworkPolicies enforce security
  ↓
GreenDevCorp accessible via minikube service nginx
```
## Documentation

See [week_13/challenge_c/](week_13/challenge_c/) for:
- Architecture diagram
- Component documentation
- Operational runbook
- Troubleshooting guide
---
