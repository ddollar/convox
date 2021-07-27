terraform {
  required_providers {
    http = {
      source = "hashicorp/http"
    }
    helm = {
      source = "hashicorp/helm"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}
