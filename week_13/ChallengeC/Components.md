# Components Documentation

## Overview

GreenDevCorp tiene 2 servicios principales, 2 servicios de red, 1 configuración centralizada, y 3 políticas de seguridad.

---

## Deployments

### 1. nginx

**Propósito:** Proxy reverso HTTP. Punto de entrada para tráfico externo.

**Imagen:** `sssalma/nginx-gsx:v1`  
**Réplicas:** 1  
**Puerto:** 80  
**CPU:** 100m request, 250m limit  
**Memory:** 64Mi request, 128Mi limit  

**Dependencias:**
- Service: nginx (NodePort)
- Acceso permitido por: allow-nginx NetworkPolicy

**Health Checks:**
- Readiness: HTTP GET / (delay 5s, period 10s)
- Liveness: HTTP GET / (delay 10s, period 30s)

**Responsabilidades:**
- Escuchar en puerto 80
- Hacer proxy a simple-app:3000
- Retornar respuestas HTTP

---

### 2. simple-app

**Propósito:** API backend. Procesa requests desde nginx.

**Imagen:** `sssalma/simple-app:v1`  
**Réplicas:** 1  
**Puerto:** 3000  
**CPU:** 100m request, 250m limit  
**Memory:** 64Mi request, 128Mi limit  

**Dependencias:**
- Service: simple-app (ClusterIP)
- ConfigMap: app-config (inyecta APP_ENV, PORT)
- Acceso permitido por: allow-simple-app NetworkPolicy

**Health Checks:**
- Readiness: HTTP GET /health (delay 5s, period 10s)
- Liveness: HTTP GET /health (delay 10s, period 30s)

**Responsabilidades:**
- Escuchar en puerto 3000
- Responder GET / con "Hello from container!"
- Responder GET /health con status 200
- Leer variables de entorno desde ConfigMap

---

## Services

### 1. nginx (NodePort)

**Tipo:** NodePort  
**Cluster IP:** 10.103.159.162  
**Puerto:** 80  
**Node Port:** 30080  
**Selector:** app=nginx  

**Acceso:**
- Externo: `localhost:30080`
- Interno: `nginx.default.svc.cluster.local:80`

**Función:** Expone nginx a tráfico externo.

---

### 2. simple-app (ClusterIP)

**Tipo:** ClusterIP  
**Cluster IP:** 10.109.237.52  
**Puerto:** 3000  
**Selector:** app=simple-app  

**Acceso:**
- Solo interno: `simple-app.default.svc.cluster.local:3000`
- No accesible desde fuera del cluster

**Función:** Expone simple-app solo dentro del cluster.

---

## ConfigMap

### app-config

**Propósito:** Centralizar configuración de aplicaciones.

**Contenido:**
APP_ENV = development
PORT = 3000
**Usado por:** simple-app (inyectado como variables de entorno)

**Cambiar configuración:**
```bash
kubectl edit configmap app-config
```

---

## Network Policies

### 1. deny-all

**Pod Selector:** <none> (todos los pods)  
**Policy Types:** Ingress, Egress  
**Reglas:** NINGUNA (bloquea todo por defecto)  

**Función:** Base de seguridad. Bloquea todo tráfico a menos que otra policy lo permita.

---

### 2. allow-nginx

**Pod Selector:** app=nginx  
**Policy Types:** Ingress, Egress  

**Ingress permitido:**
- Cualquier fuente
- Puerto 80
- Protocolo TCP

**Egress permitido:**
- Destino: pods con label app=simple-app
- Puerto 3000
- Protocolo TCP

**Función:** Permite nginx recibir tráfico externo y comunicarse con simple-app.

---

### 3. allow-simple-app

**Pod Selector:** app=simple-app  
**Policy Types:** Ingress  

**Ingress permitido:**
- Fuente: pods con label app=nginx
- Puerto 3000
- Protocolo TCP

**Egress permitido:** NINGUNO (bloqueado)

**Función:** Permite simple-app recibir solo desde nginx. Sin egress (no inicia conexiones).

---

## Dependencias y Comunicación
External Traffic (localhost:30080)
↓
nginx Service (NodePort)
↓
nginx Pod (port 80)
↓ (proxy)
simple-app Service (ClusterIP)
↓
simple-app Pod (port 3000)
↓ (lee config)
app-config ConfigMap

---

## Ciclo de vida de una request

1. **Usuario:** `curl localhost:30080`
2. **Kubernetes:** Ruta a través de NodePort 30080
3. **nginx Pod:** Recibe en puerto 80
4. **nginx:** Valida allow-nginx policy → permitido ✅
5. **nginx:** Hace proxy a simple-app:3000
6. **simple-app Pod:** Recibe en puerto 3000
7. **simple-app:** Valida allow-simple-app policy → permitido ✅
8. **simple-app:** Lee PORT de ConfigMap
9. **simple-app:** Procesa y responde
10. **nginx:** Retorna respuesta al usuario
11. **Usuario:** Recibe respuesta