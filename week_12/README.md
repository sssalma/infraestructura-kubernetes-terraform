# Week 12: Network Design & Identity

## Objetivo

Diseñar una arquitectura de red segura y escalable para GreenDevCorp, implementar segmentación mediante Kubernetes NetworkPolicies, y definir una estrategia de identidad centralizada que permita gestionar quién puede acceder a qué.

---

## Estructura

```
week_12/
├── kubernetes/
│   ├── network-policy-deny-all.yaml        # Política por defecto (defensa en profundidad)
│   ├── network-policy-nginx.yaml           # Permite tráfico web a nginx
│   ├── network-policy-simple-app.yaml      # Permite tráfico desde nginx a app
│   └── README.md                           # Explicación de NetworkPolicies
├── network-architecture.md                 # Diagrama y diseño de redes
├── cidr-plan.md                            # Plan de direccionamiento IP
├── core-services-research.md               # DNS, DHCP, NTP (investigación)
├── identity-management.md                  # Identity & centralized auth
└── security-analysis.md                    # Análisis de amenazas y mitigaciones
```

---

## 1. Arquitectura de red de GreenDevCorp

GreenDevCorp ha crecido a 20+ personas y necesita:
- **Aislamiento de entornos**: dev, staging, producción no pueden intercomunicarse
- **Principio de menor privilegio**: solo el tráfico explícitamente permitido
- **Defense in depth**: múltiples capas de seguridad
- **Escalabilidad**: fácil agregar nuevos servicios y usuarios

### Diagrama de arquitectura

```
┌──────────────────────────────────────────────────────────────────────────┐
│                         INTERNET / EXTERNAL                              │
└────────────────────────────────┬─────────────────────────────────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │   DMZ (Ingress/LB)      │
                    │   Port 80, 443          │
                    └────────────┬────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
         ▼                       ▼                       ▼
    ┌────────────┐         ┌────────────┐         ┌────────────┐
    │ DEVELOPMENT│         │  STAGING   │         │ PRODUCTION │
    │ 10.0.1.0/24│         │ 10.0.2.0/24│         │ 10.0.3.0/24│
    │            │         │            │         │            │
    │ ┌─────────┐│         │ ┌─────────┐│         │ ┌─────────┐│
    │ │ nginx   ││         │ │ nginx   ││         │ │ nginx   ││
    │ │ :80     │┼─────────┼─│ :80     │┼─────────┼─│ :80     ││
    │ │(deny-all)│         │ │(deny-all)│         │(deny-all) ││
    │ └────┬────┘│         │ └────┬────┘│         │ └────┬────┘│
    │      │     │         │      │     │         │      │     │
    │      ▼     │         │      ▼     │         │      ▼     │
    │ ┌─────────┐│         │ ┌─────────┐│         │ ┌────────┐ │
    │ │simple-app│         │ │simple-app│         │ │simple-app│
    │ │:3000   │ │         │ │:3000   │ │         │ │:3000   │ │
    │ │(allow- │ │         │ │(allow- │ │         │ │(allow- │ │
    │ │ app)   │ │         │ │ app)   │ │         │ │ app)   │ │
    │ └────┬───┘ │         │ └────┬───┘ │         │ └────┬───┘ │
    │      │     │         │      │     │         │      │     │
    │      ▼     │         │      ▼     │         │      ▼     │
    │ ┌────────┐ │         │ ┌────────┐ │         │ ┌────────┐ │
    │ │Database│ │         │ │Database│ │         │ │Database│ │
    │ │(opt)   │ │         │ │(opt)   │ │         │ │(opt)   │ │
    │ └────────┘ │         │ └────────┘ │         │ └────────┘ │
    │            │         │            │         │            │
    │ Policies:  │         │ Policies:  │         │ Policies:  │
    │ - deny-all │         │ - deny-all │         │ - deny-all │
    │ - allow-ngnx         │ - allow-ngnx         │- allow-ngnx│
    │ - allow-app │        │ - allow-app│         │ - allow-app│
    └─────────────┘        └────────────┘         └────────────┘

         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │ EXTERNAL PARTNERS       │
                    │ 10.0.10.0/24            │
                    │ (Limited API access)    │
                    └─────────────────────────┘

                    ┌──────────────────────────┐
                    │ MONITORING / LOGGING     │
                    │ 10.0.100.0/24            │
                    │ Prometheus, Grafana, ELK │
                    └──────────────────────────┘
```

---

## 2. Principios de seguridad implementados

### Defensa en profundidad (Defense in Depth)

1. **Capa 1: Firewall del host** — iptables/netfilter en cada nodo
2. **Capa 2: Kubernetes NetworkPolicies** — filtrado en la red overlay
3. **Capa 3: Identity & Authentication** — solo usuarios autenticados
4. **Capa 4: Autorización (RBAC)** — Kubernetes role-based access control
5. **Capa 5: Auditoría** — logs de quién hizo qué y cuándo

### Principio de menor privilegio (Least Privilege)

- **Por defecto:** NEGAR todo
- **Explícitamente permitido:** solo lo necesario
- **Revisión periódica:** eliminar permisos que ya no se usan

---

## 3. Kubernetes NetworkPolicies

Las 3 políticas implementadas trabajan conjuntamente (archivos YAML en `kubernetes/`):

| Política | Propósito | Regla clave |
|----------|-----------|------------|
| **deny-all** | Base: negar todo por defecto | Default: Ingress + Egress bloqueados |
| **allow-nginx** | Exponer servicio al exterior | Ingress: 80 (público), Egress: simple-app:3000 |
| **allow-simple-app** | Recibir tráfico desde nginx | Ingress: solo desde nginx:80, Egress: bloqueado |

**Principio:** Principio de menor privilegio. Por defecto NEGAR TODO, luego abrir solo lo necesario.

---

## 4. Cómo verificar que las políticas funcionan

```bash
# 1. Deployar las policies
kubectl apply -f kubernetes/

# 2. Verificar que están activas
kubectl get networkpolicies

# 3. Probar: nginx PUEDE alcanzar simple-app
kubectl exec -it <nginx-pod> -- curl http://simple-app:3000
# Resultado esperado: "Hello from container!" ✓

# 4. Probar: simple-app NO PUEDE hacer llamadas salientes
kubectl exec -it <simple-app-pod> -- curl http://nginx:80
# Resultado esperado: timeout o connection refused (bloqueado) ✓

# 5. Probar: desde fuera del cluster se puede alcanzar nginx
curl http://<nginx-service-ip>:80
# Resultado esperado: página de GreenDevCorp ✓

# 6. Probar: desde fuera NO se puede alcanzar simple-app directamente
curl http://<simple-app-pod-ip>:3000
# Resultado esperado: connection refused (bloqueado) ✓
```

---

## 5. Conceptos clave aprendidos

### Segmentación de red

Una sola red sin segmentación = una brecha de seguridad compromete todo. 
Hay que dividir en subnets por entorno:
- **Dev**: experimentación, menos rígido
- **Staging**: refleja producción, validación antes de deploy
- **Prod**: máxima seguridad, auditoría, acceso mínimo

### Stateless policies

Las NetworkPolicies son **stateless**: una política permite ´que `ingress` en puerto 80,sólo permite esa acción a menos que se indique explícitamente lo contrario ambas direcciones.

Hay que tener en cuenta que las network policies protegen a nivel de pods: no protegen ataques de códigos maliciosos dentro del mismo pod, ni autentican usuarios. 


Para máxima seguridad, combina con:
- **Secrets management** (no hardcodear credenciales)
- **mTLS** (mutual TLS entre servicios)
- **RBAC** (control de acceso basado en roles)
- **Auditoría** (logs de todo)
- **Identidad centralizada** (tema de esta semana)
