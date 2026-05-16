# Challenge B: Full Integration Test

1. Instalación Minikube en Windows
2. Arrancar Minikube con Docker driver
3. Crear network-policies.tf para integrar las 3 policies en Terraform
4. `terraform destroy` para limpiar
5. `terraform apply` para desplegar todo desde cero

## Resultados
PODS:
nginx-595c84dbd6-d5pr9        1/1 Running
simple-app-6787bcc859-fdxgs   1/1 Running
SERVICES:
nginx        NodePort    10.103.159.162   80:30080/TCP
simple-app   ClusterIP   10.109.237.52    3000/TCP
NETWORK POLICIES:
deny-all           - Bloquea todo (base)
allow-nginx        - Permite ingress:80, egress a app:3000
allow-simple-app   - Permite ingress desde nginx:3000

## Tiempos de deployment

- nginx: 16 segundos
- simple-app: 46 segundos
- Total: ~60 segundos

## Issues encontrados y solucionados

1. Minikube no estaba instalado → Instalación manual
2. Imagen con nombre inexistente en el Docker hub → Update del terraform/network-policies.tf a `simple-app:v1`
3. Deployment se quedó colgado → Limpiamos manualmente y reintentamos

## Verificación

✅ Servicios corriendo
✅ Se comunican entre sí (nginx → app)
✅ NetworkPolicies activas y funcionando
✅ IaC despliega correctamente desde cero
