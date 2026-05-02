# Week 10: Orchestration (Kubernetes)

## Objetivo

Desplegar el stack de GreenDevCorp en Kubernetes local (Minikube) para entender cómo funciona la orquestación en producción: autoescalado, recuperación de fallos, rolling updates y comunicación entre servicios.

---

## Estructura

```
week_10/
└── kubernetes/
    ├── configmap.yaml            # Configuración centralizada
    ├── nginx-deployment.yaml     # Deployment del servidor web
    ├── nginx-service.yaml        # Exposición externa de nginx
    ├── simple-app-deployment.yaml  # Deployment del backend Flask
    ├── simple-app-service.yaml   # Servicio interno del backend
    └── README.md                 # Esta documentación
```

---

## Arquitectura en Kubernetes

```
                     ┌──────────────────────────────────────────────┐
  Internet           │                 Minikube cluster              │
                     │                                               │
  :30080 ────────────┤──▶  Service/nginx (NodePort)                  │
                     │         │                                     │
                     │         ▼                                     │
                     │    [Pod: nginx]  ◀──── Deployment/nginx       │
                     │         │                                     │
                     │         │ http://simple-app:3000              │
                     │         ▼                                     │
                     │  Service/simple-app (ClusterIP)               │
                     │         │                                     │
                     │         ▼                                     │
                     │  [Pod: simple-app] ◀── Deployment/simple-app  │
                     │                                               │
                     │  ConfigMap/app-config ──▶ simple-app env vars │
                     └──────────────────────────────────────────────┘
```

---

## Recursos de Kubernetes usados

### Deployment

Un Deployment es la forma estándar de gestionar pods stateless en Kubernetes. Define:
- Cuántas réplicas correr (`replicas`)
- Qué imagen usar y con qué configuración
- Cómo detectar que un pod está sano (probes)
- Recursos que puede consumir (requests/limits)

La diferencia clave respecto a crear un Pod directamente: si el pod muere, el Deployment lo vuelve a crear automáticamente. Un pod standalone muerto se queda muerto.

### Service

Un Service expone un conjunto de pods mediante un nombre DNS estable. Sin Service, los pods tienen IPs internas que cambian cada vez que el pod se reinicia.

Tipos usados:
- **ClusterIP** (simple-app): solo accesible desde dentro del cluster. Correcto para backends internos.
- **NodePort** (nginx): expone el servicio en un puerto del nodo (el host Minikube), permitiendo acceso externo. En producción real usaríamos un `LoadBalancer` o un `Ingress`.

### ConfigMap

Almacena configuración en forma de clave-valor, desacoplada de la imagen. El deployment de `simple-app` hace `envFrom: configMapRef` para inyectar todos los valores como variables de entorno. Esto cumple el mismo papel que el `.env` de Compose, pero gestionado por Kubernetes.

---

## Despliegue paso a paso

### 1. Arrancar Minikube

```bash
minikube start
kubectl cluster-info
```

### 2. Aplicar todos los manifests

```bash
# Desde la carpeta kubernetes/
kubectl apply -f .

# Salida esperada:
# configmap/app-config created
# deployment.apps/nginx created
# service/nginx created
# deployment.apps/simple-app created
# service/simple-app created
```

### 3. Verificar que los pods están Running

```bash
kubectl get pods
# NAME                          READY   STATUS    RESTARTS   AGE
# nginx-xxxx-yyyy               1/1     Running   0          30s
# simple-app-xxxx-yyyy          1/1     Running   0          30s

kubectl get services
# NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
# nginx        NodePort    10.96.x.x       <none>        80:30080/TCP     30s
# simple-app   ClusterIP   10.96.x.x       <none>        3000/TCP         30s
```

### 4. Probar comunicación entre servicios

```bash
# Entrar al pod de nginx y llamar al backend por nombre de servicio
kubectl exec -it deploy/nginx -- curl http://simple-app:3000
# Hello from container!

kubectl exec -it deploy/nginx -- curl http://simple-app:3000/health
# {"status": "ok"}
```

### 5. Acceder desde fuera del cluster

```bash
# Obtener la URL de acceso
minikube service nginx --url
# http://192.168.x.x:30080

# O acceder directamente
curl $(minikube service nginx --url)
```

---

## Testing de escalado

```bash
# Escalar simple-app a 3 réplicas
kubectl scale deployment simple-app --replicas=3

# Observar cómo se crean los nuevos pods
kubectl get pods --watch

# Kubernetes balancea el tráfico entre las 3 réplicas automáticamente
# El Service actúa como load balancer interno

# Volver a 1 réplica
kubectl scale deployment simple-app --replicas=1
```

---

## Testing de resiliencia

```bash
# Borrar un pod manualmente
kubectl delete pod <nombre-del-pod>

# Kubernetes detecta que falta una réplica y crea un nuevo pod inmediatamente
kubectl get pods --watch

# El Deployment garantiza que siempre haya 'replicas' pods corriendo
```

---

## Resource requests y limits

Cada contenedor tiene definidos:

```yaml
resources:
  requests:
    memory: "64Mi"
    cpu: "100m"
  limits:
    memory: "128Mi"
    cpu: "250m"
```

- **requests**: lo que Kubernetes reserva para el pod al planificarlo en un nodo. Garantiza que el pod tendrá esos recursos disponibles.
- **limits**: el máximo que puede consumir. Si un pod supera el límite de memoria, Kubernetes lo mata (OOMKilled). Si supera CPU, lo throttlea.

Sin limits, un pod con un bug podría consumir todos los recursos del nodo y afectar al resto de servicios.

---

## Probes de salud

Cada deployment define dos tipos de probe:

### readinessProbe

Determina si el pod está listo para recibir tráfico. Kubernetes no envía tráfico al pod hasta que esta probe pase. Útil para evitar que el Service envíe requests a un pod que todavía está inicializando.

### livenessProbe

Determina si el pod sigue vivo. Si falla repetidamente, Kubernetes reinicia el pod. Detecta situaciones de deadlock donde el proceso sigue corriendo pero ha dejado de responder.

---

## Comparativa: Compose vs Kubernetes

| Característica | Docker Compose | Kubernetes |
|----------------|---------------|------------|
| Escenario | Desarrollo local | Producción |
| Escalado | Manual (`--scale`) | Automático (HPA) |
| Recuperación | `restart: always` | Deployment controller |
| Multi-nodo | No | Sí |
| Complejidad | Baja | Alta |
| Configuración | Un fichero YAML | Múltiples manifests |

Compose es suficiente para un equipo pequeño en desarrollo. Cuando GreenDevCorp escale a producción con múltiples servidores y necesite zero-downtime deploys, Kubernetes justifica su complejidad.

---

## Comandos útiles

```bash
# Ver descripción detallada de un recurso
kubectl describe pod <nombre>
kubectl describe deployment nginx

# Ver logs de un pod
kubectl logs deploy/nginx
kubectl logs deploy/simple-app

# Ver el estado del ConfigMap
kubectl get configmap app-config -o yaml

# Eliminar todo lo desplegado
kubectl delete -f .
```
