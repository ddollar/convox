resource "kubernetes_cluster_role" "atom" {
  metadata {
    name = "atom"
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }
}

resource "kubernetes_cluster_role_binding" "atom" {
  metadata {
    name = "atom-${var.name}"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "atom"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "atom-${var.name}"
    namespace = var.namespace
  }
}

resource "kubernetes_service_account" "atom" {
  metadata {
    namespace = var.namespace
    name      = "atom-${var.name}"
  }
}

resource "kubernetes_deployment" "atom" {
  metadata {
    namespace = var.namespace
    name      = "atom"

    labels = {
      app     = "system"
      name    = "atom"
      rack    = var.rack
      service = "atom"
      system  = "convox"
      type    = "service"
    }
  }

  spec {
    revision_history_limit = 0

    selector {
      match_labels = {
        name    = "atom"
        service = "atom"
        system  = "convox"
        type    = "service"
      }
    }

    strategy {
      type = "RollingUpdate"

      rolling_update {
        max_surge       = 1
        max_unavailable = 0
      }
    }

    template {
      metadata {
        annotations = {
          "scheduler.alpha.kubernetes.io/critical-pod" : ""
        }

        labels = {
          app     = "system"
          name    = "atom"
          rack    = var.rack
          service = "atom"
          system  = "convox"
          type    = "service"
        }
      }

      spec {
        automount_service_account_token = true
        share_process_namespace         = true
        service_account_name            = kubernetes_service_account.atom.metadata.0.name

        container {
          name              = "system"
          args              = ["atom"]
          image             = "convox/convox:${var.release}"
          image_pull_policy = "Always"

          resources {
            requests {
              cpu    = "32m"
              memory = "32Mi"
            }
          }
        }
      }
    }
  }
}
