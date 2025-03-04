data "google_client_config" "current" {}

data "google_project" "current" {}

resource "random_string" "password" {
  length  = 64
  special = true
}

resource "google_container_cluster" "rack" {
  provider = google-beta

  name     = var.name
  location = data.google_client_config.current.region
  network  = google_compute_network.rack.name

  remove_default_node_pool = true
  initial_node_count       = 1

  release_channel {
    channel = "REGULAR"
  }

  workload_identity_config {
    identity_namespace = "${data.google_project.current.project_id}.svc.id.goog"
  }

  ip_allocation_policy {}

  master_auth {
    username = "gcloud"
    password = random_string.password.result

    client_certificate_config {
      issue_client_certificate = true
    }
  }
}

resource "google_container_node_pool" "rack" {
  provider = google-beta

  name               = "${google_container_cluster.rack.name}-nodes-${var.node_type}"
  location           = google_container_cluster.rack.location
  cluster            = google_container_cluster.rack.name
  initial_node_count = 1

  autoscaling {
    min_node_count = 1
    max_node_count = 1000
  }

  node_config {
    machine_type = var.node_type
    preemptible  = var.preemptible

    metadata = {
      disable-legacy-endpoints = "true"
    }

    workload_metadata_config {
      node_metadata = "GKE_METADATA_SERVER"
    }

    service_account = google_service_account.nodes.email

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/devstorage.read_write",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 1
  }

  lifecycle {
    create_before_destroy = true
  }
}

provider "kubernetes" {
  alias = "direct"

  cluster_ca_certificate = base64decode(google_container_cluster.rack.master_auth.0.cluster_ca_certificate)
  host                   = "https://${google_container_cluster.rack.endpoint}"
  username               = "gcloud"
  password               = random_string.password.result
}

resource "kubernetes_cluster_role_binding" "client" {
  provider = kubernetes.direct

  metadata {
    name = "client-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind = "User"
    name = "client"
  }
}
