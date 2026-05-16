# Operational Runbook

## Prerequisites

- Minikube running
- kubectl configured  
- Terraform installed
- Docker (for Minikube)

---

## Q&A

### How do you deploy a new version?

**Método 1: Con Terraform (recomendado)**
```bash
cd terraform/
terraform apply
```

**Método 2: Cambiar imagen sin Terraform**
```bash
kubectl set image deployment/nginx nginx=sssalma/nginx-gsx:v2
kubectl set image deployment/simple-app simple-app=sssalma/simple-app:v2
```

**Verificar progreso:**
```bash
kubectl rollout status deployment/nginx
kubectl rollout status deployment/simple-app
```

**Volver a versión anterior:**
```bash
kubectl rollout undo deployment/nginx
kubectl rollout undo deployment/simple-app
```

---

### How do you scale a service?

**Escalar nginx a 3 réplicas:**
```bash
kubectl scale deployment/nginx --replicas=3
```

**Escalar simple-app a 2 réplicas:**
```bash
kubectl scale deployment/simple-app --replicas=2
```

**Verificar:**
```bash
kubectl get pods
```

**Volver a 1 réplica:**
```bash
kubectl scale deployment/nginx --replicas=1
kubectl scale deployment/simple-app --replicas=1
```

---

### How do you check logs?

**Logs de nginx:**
```bash
kubectl logs deployment/nginx
```

**Logs de simple-app:**
```bash
kubectl logs deployment/simple-app
```

**Logs en tiempo real (follow):**
```bash
kubectl logs -f deployment/nginx
kubectl logs -f deployment/simple-app
```

**Logs de un pod específico:**
```bash
kubectl logs <POD_NAME>
```

**Últimas 100 líneas:**
```bash
kubectl logs deployment/nginx --tail=100
```

---

### How do you troubleshoot a failure?

**Paso 1: Ver estado de los pods**
```bash
kubectl get pods
```

**Paso 2: Describir el pod con problemas**
```bash
kubectl describe pod <POD_NAME>
```

Buscar en sección "Events" → Mensajes de error.

**Paso 3: Ver logs**
```bash
kubectl logs <POD_NAME>
```

**Problemas comunes y soluciones:**

**ImagePullBackOff** → Imagen no existe
```bash
# Verificar que existe
docker pull sssalma/nginx-gsx:v1
# Si falla, cambiar nombre en terraform y redeployar
```

**CrashLoopBackOff** → Pod está crasheando
```bash
# Ver qué está mal
kubectl logs <POD_NAME>
# Corregir código y hacer push a Docker Hub
# Luego: kubectl set image deployment/app app=<NEW_IMAGE>
```

**Pending** → No hay recursos
```bash
kubectl get nodes
kubectl describe nodes
```

**Tráfico bloqueado (nginx no alcanza simple-app)**
```bash
# Verificar labels
kubectl get pods --show-labels

# Verificar policies
kubectl get networkpolicies
kubectl describe networkpolicy allow-nginx

# Probar conectividad
kubectl exec -it <NGINX_POD> -- curl http://simple-app:3000
```

**Conexión rechazada (curl localhost:30080 falla)**
```bash
# Verificar nginx está running
kubectl get pod -l app=nginx

# Verificar service existe
kubectl get service nginx

# Si falla, revisar logs y redeployar
kubectl logs deployment/nginx
terraform destroy
terraform apply
```

---

## Bonus: Configuration Changes

**Ver configuración actual:**
```bash
kubectl get configmap app-config -o yaml
```

**Editar configuración:**
```bash
kubectl edit configmap app-config
```

**Cambiar via CLI:**
```bash
kubectl patch configmap app-config -p '{"data":{"APP_ENV":"production"}}'
```

---

## Cleanup

**Borrar todo:**
```bash
cd terraform/
terraform destroy
```