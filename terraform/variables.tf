variable "kube_context" {
  description = "Contexto de kubectl a usar (minikube para desarrollo local)"
  type        = string
  default     = "minikube"
}

variable "app_env" {
  description = "Entorno de ejecución de la aplicación"
  type        = string
  default     = "development"
}

variable "app_port" {
  description = "Puerto de la simple-app"
  type        = number
  default     = 3000
}

variable "nginx_replicas" {
  description = "Número de réplicas del deployment de nginx"
  type        = number
  default     = 1
}

variable "app_replicas" {
  description = "Número de réplicas del deployment de simple-app"
  type        = number
  default     = 1
}

variable "dockerhub_user" {
  description = "Usuario de Docker Hub donde están las imágenes"
  type        = string
  default     = "sssalma"
}

variable "image_tag" {
  description = "Tag de las imágenes Docker a desplegar (usar commit SHA en CI)"
  type        = string
  default     = "v1"
}