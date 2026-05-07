output "nginx_service_type" {
  description = "Tipo de servicio de nginx"
  value       = kubernetes_service.nginx.spec[0].type
}

output "nginx_node_port" {
  description = "NodePort asignado a nginx (acceso externo en Minikube)"
  value       = kubernetes_service.nginx.spec[0].port[0].node_port
}

output "simple_app_service_type" {
  description = "Tipo de servicio de simple-app"
  value       = kubernetes_service.simple_app.spec[0].type
}

output "app_config_data" {
  description = "Configuración inyectada en la app via ConfigMap"
  value       = kubernetes_config_map.app_config.data
}