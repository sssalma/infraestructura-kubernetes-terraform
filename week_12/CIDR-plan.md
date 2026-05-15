# CIDR Plan: GreenDevCorp

## Actualmente

Single namespace (default) con 2 pods:
- nginx (puerto 80)
- simple-app (puerto 3000)

Sin asignación CIDR formal. IPs asignadas automáticamente por Kubernetes CNI.

---
## Propuesta futura (no implementado)
Para múltiples entornos se necesitaría:
10.0.0.0/16
├── 10.0.1.0/24 → Development
├── 10.0.2.0/24 → Staging
├── 10.0.3.0/24 → Production
└── 10.0.100.0/24 → Monitoring
## Conclusión

Hoy: Kubernetes asigna IPs automáticamente. 