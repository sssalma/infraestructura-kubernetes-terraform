# Infraestructura contenerizada: Docker, Kubernetes y Terraform

Infraestructura completa de una aplicación web para *GreenDevCorp*, construida de forma
incremental a lo largo del curso: de contenedores sueltos a un clúster de Kubernetes
declarado íntegramente como **infraestructura como código** con Terraform, con políticas
de red restrictivas y CI automatizada.

> Práctica 2 de *Gestió de Sistemes i Xarxes* — Grau en Enginyeria Informàtica, URV.
> Trabajo en pareja: Nawfal Aissaoui y Salma Jadiani.

## Arquitectura

```text
            ── NodePort 30080 ──►  nginx Pod  ──►  simple-app Pod
                                  (reverse proxy)    (Flask + Redis)
                                        │                  │
                                   ConfigMap app-config ────┘
```

| Componente | Tipo de Service | Acceso |
|---|---|---|
| `nginx` | NodePort | Externo, puerto 30080 |
| `simple-app` | ClusterIP | Solo interno |

La app únicamente es alcanzable a través de nginx: no se expone al exterior.

## Seguridad de red

Tres `NetworkPolicy` que implementan un modelo de **denegación por defecto**:

1. `deny-all` — se bloquea todo el tráfico del namespace.
2. `allow-nginx` — se permite explícitamente que nginx hable con la app.
3. `allow-simple-app` — se permite explícitamente que la app reciba tráfico de nginx.

Así, cualquier comunicación no contemplada queda cortada, en lugar de depender de
recordar bloquear cada caso.

## Evolución por semanas

| Semana | Contenido |
|---|---|
| `week_8/` | Contenedores: imagen de nginx como reverse proxy e imagen de la app Flask |
| `week_9/` | Orquestación local con Docker Compose |
| `week_10/` | Migración a Kubernetes: Deployments, Services y ConfigMap en YAML |
| `week_12/` | NetworkPolicies, plan de CIDR, gestión de identidades y análisis de seguridad |
| `week_13/` | Retos finales: diagnóstico, documentación de componentes, runbook operativo y troubleshooting |
| `terraform/` | IaC: todo lo anterior declarado en Terraform (semanas 11 y 13) |

## Infraestructura como código

`terraform/` despliega el conjunto completo sobre un clúster (Minikube) usando el
provider `hashicorp/kubernetes`: el ConfigMap, ambos Deployments, ambos Services y las
NetworkPolicies. Todo lo parametrizable está en `variables.tf` — contexto de kubectl,
usuario de Docker Hub, tag de imagen, número de réplicas, entorno y puerto — de modo que
el mismo código sirve para distintos entornos sin editarlo.

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

El estado de Terraform (`*.tfstate`) está excluido del repositorio.

## CI

`.github/workflows/ci.yml` construye y publica en Docker Hub las dos imágenes en cada
push a `main`, etiquetándolas con `latest` y con el SHA del commit, lo que permite
desplegar una versión exacta y volver atrás. Las credenciales se leen de los secrets del
repositorio (`DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`).

## Documentación

- `week_12/CIDR-plan.md` — propuesta de segmentación en subredes (documentada, no desplegada)
- `week_12/security-analysis.md` — análisis de seguridad
- `week_12/identity-management.md` — gestión de identidades y accesos
- `week_13/ChallengeC/OperationalRunBook.md` — runbook de operación
- `week_13/ChallengeC/TroubleShooting.md` — guía de diagnóstico
- `Memoria.pdf` — memoria de la práctica

## Alcance

Implementado y desplegado: Docker (2 imágenes), Kubernetes (2 Deployments, 2 Services,
3 NetworkPolicies, 1 ConfigMap), Terraform (IaC completa) y CI en GitHub Actions.
Documentado pero no desplegado: el plan de CIDR con múltiples subredes.

## Stack

Docker · Docker Compose · Kubernetes · Minikube · Terraform · GitHub Actions · nginx · Flask · Redis
