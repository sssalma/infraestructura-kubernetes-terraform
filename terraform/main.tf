# Proveedor de Kubernetes - conecta Terraform con el cluster local (Minikube)
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = var.kube_context
}

# ConfigMap con la configuración de la app
resource "kubernetes_config_map" "app_config" {
  metadata {
    name = "app-config"
  }

  data = {
    APP_ENV = var.app_env
    PORT    = tostring(var.app_port)
  }
}

# Deployment de nginx
resource "kubernetes_deployment" "nginx" {
  metadata {
    name = "nginx"
    labels = {
      app  = "nginx"
      week = "11"
    }
  }

  spec {
    replicas = var.nginx_replicas

    selector {
      match_labels = {
        app = "nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }

      spec {
        container {
          name  = "nginx"
          image = "${var.dockerhub_user}/nginx-gsx:${var.image_tag}"

          port {
            container_port = 80
          }

          resources {
            requests = {
              memory = "64Mi"
              cpu    = "100m"
            }
            limits = {
              memory = "128Mi"
              cpu    = "250m"
            }
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 10
            period_seconds        = 30
          }
        }
      }
    }
  }
}

# Service de nginx (NodePort para acceso externo en Minikube)
resource "kubernetes_service" "nginx" {
  metadata {
    name = "nginx"
  }

  spec {
    selector = {
      app = "nginx"
    }

    type = "NodePort"

    port {
      port        = 80
      target_port = 80
      node_port   = 30080
    }
  }
}

# Deployment de simple-app
resource "kubernetes_deployment" "simple_app" {
  metadata {
    name = "simple-app"
    labels = {
      app  = "simple-app"
      week = "11"
    }
  }

  spec {
    replicas = var.app_replicas

    selector {
      match_labels = {
        app = "simple-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "simple-app"
        }
      }

      spec {
        container {
          name  = "simple-app"
          image = "${var.dockerhub_user}/simple-app:${var.image_tag}"

          port {
            container_port = 3000
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.app_config.metadata[0].name
            }
          }
          env {
            name  = "REDIS_HOST"
            value = "redis"
          }
          env {
            name  = "REDIS_PORT"
            value = "6379"
          }

          resources {
            requests = {
              memory = "64Mi"
              cpu    = "100m"
            }
            limits = {
              memory = "128Mi"
              cpu    = "250m"
            }
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 3000
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 3000
            }
            initial_delay_seconds = 10
            period_seconds        = 30
          }
        }
      }
    }
  }
}

# Service de simple-app (ClusterIP - solo accesible desde dentro del cluster)
resource "kubernetes_service" "simple_app" {
  metadata {
    name = "simple-app"
  }

  spec {
    selector = {
      app = "simple-app"
    }

    type = "ClusterIP"

    port {
      port        = 3000
      target_port = 3000
    }
  }
}

# Deployment de redis (BD per al comptador de visites)
resource "kubernetes_deployment" "redis" {
  metadata {
    name = "redis"
    labels = {
      app  = "redis"
      week = "11"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "redis"
      }
    }

    template {
      metadata {
        labels = {
          app = "redis"
        }
      }

      spec {
        container {
          name  = "redis"
          image = "redis:7-alpine"

          port {
            container_port = 6379
          }

          resources {
            requests = {
              memory = "64Mi"
              cpu    = "100m"
            }
            limits = {
              memory = "128Mi"
              cpu    = "250m"
            }
          }
        }
      }
    }
  }
}

# Service de redis (ClusterIP - només accessible dins del cluster)
resource "kubernetes_service" "redis" {
  metadata {
    name = "redis"
  }

  spec {
    selector = {
      app = "redis"
    }

    type = "ClusterIP"

    port {
      port        = 6379
      target_port = 6379
    }
  }
}