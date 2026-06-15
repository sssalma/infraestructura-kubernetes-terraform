# NetworkPolicy 1: Deny all traffic (default policy)
# Aplica a todos los pods del namespace
resource "kubernetes_network_policy" "deny_all" {
  metadata {
    name = "deny-all"
  }

  spec {
    pod_selector {}

    policy_types = ["Ingress", "Egress"]
  }
}

# NetworkPolicy 2: Allow nginx
# Ingress: puerto 80 (público)
# Egress: solo a simple-app en puerto 3000
resource "kubernetes_network_policy" "allow_nginx" {
  metadata {
    name = "allow-nginx"
  }

  spec {
    pod_selector {
      match_labels = {
        app = "nginx"
      }
    }

    policy_types = ["Ingress", "Egress"]

    ingress {
      ports {
        port     = "80"
        protocol = "TCP"
      }
    }

    egress {
      to {
        pod_selector {
          match_labels = {
            app = "simple-app"
          }
        }
      }


      ports {
        port     = "3000"
        protocol = "TCP"
      }
    }
    egress {
      to {
        namespace_selector {}
      }
      ports {
        port     = "53"
        protocol = "UDP"
      }
      ports {
        port     = "53"
        protocol = "TCP"
      }
    }
  }

  depends_on = [kubernetes_deployment.nginx, kubernetes_deployment.simple_app]
}

# NetworkPolicy 3: Allow simple-app
# Ingress: solo desde nginx en puerto 3000
# Egress: bloqueado (no inicia conexiones)
resource "kubernetes_network_policy" "allow_simple_app" {
  metadata {
    name = "allow-simple-app"
  }

  spec {
    pod_selector {
      match_labels = {
        app = "simple-app"
      }
    }

    policy_types = ["Ingress", "Egress"]

    ingress {
      from {
        namespace_selector {}
        pod_selector {
          match_labels = {
            app = "nginx"
          }
        }
      }
      ports {
        port     = "3000"
        protocol = "TCP"
      }
    }

    egress {
      to {
        pod_selector {
          match_labels = {
            app = "redis"
          }
        }
      }
      ports {
        port     = "6379"
        protocol = "TCP"
      }
    }

    egress {
      to {
        namespace_selector {}
      }
      ports {
        port     = "53"
        protocol = "UDP"
      }
      ports {
        port     = "53"
        protocol = "TCP"
      }
    }
  }

  depends_on = [kubernetes_deployment.simple_app, kubernetes_deployment.nginx]
}

# NetworkPolicy: redis només rep de simple-app
resource "kubernetes_network_policy" "allow_redis" {
  metadata {
    name = "allow-redis"
  }

  spec {
    pod_selector {
      match_labels = {
        app = "redis"
      }
    }

    policy_types = ["Ingress"]

    ingress {
      from {
        namespace_selector {}
        pod_selector {
          match_labels = {
            app = "simple-app"
          }
        }
      }
      ports {
        port     = "6379"
        protocol = "TCP"
      }
    }
  }

  depends_on = [kubernetes_deployment.redis, kubernetes_deployment.simple_app]
}