# week_13/challenge_c/TROUBLESHOOTING.md

# Troubleshooting Guide

## Quick Problems & Fixes

### ImagePullBackOff
**Problem:** Pod no arranca, imagen no encontrada  
**Fix:**
```bash
# Verificar nombre correcto en terraform/main.tf
# ✅ sssalma/simple-app:v1
# ❌ sssalma/simple-app-gsx:v1

terraform apply
```

---

### CrashLoopBackOff
**Problem:** Pod arranca y crashea repetidamente  
**Fix:**
```bash
kubectl logs <POD_NAME>
# Ver error en logs, corregir código y redeployar
```

---

### NetworkPolicy Blocking
**Problem:** nginx no puede alcanzar simple-app  
**Fix:**
```bash
# Verificar labels
kubectl get pods --show-labels

# Verificar policies
kubectl describe networkpolicy allow-nginx

# Test
$NGINX_POD = kubectl get pod -l app=nginx -o jsonpath='{.items[0].metadata.name}'
kubectl exec -it $NGINX_POD -- curl http://simple-app:3000
# Debe retornar respuesta
```

---

### Can't Access from Windows
**Problem:** `localhost:30080` no funciona  
**Fix:**
```powershell
minikube service nginx
```

---

### Pod Stuck in Pending
**Problem:** Pod no arranca  
**Fix:**
```bash
kubectl describe pod <POD_NAME>
# Ver Events → buscar error

# Verificar recursos
minikube status
kubectl get nodes
```

---

### Terraform State Out of Sync
**Problem:** "deployment already exists"  
**Fix:**
```bash
kubectl delete deployment --all
kubectl delete service --all
kubectl delete configmap --all
kubectl delete networkpolicy --all

terraform apply
```

---

### Deployment Taking Too Long
**Problem:** `terraform apply` >3 minutos  
**Fix:**
```bash
# Ver logs en tiempo real
kubectl logs -f deployment/simple-app

# Si hay error, refrescar
terraform destroy
terraform apply
```

---

## When Nothing Works

```bash
terraform destroy
terraform apply
kubectl get pods
minikube service nginx
```