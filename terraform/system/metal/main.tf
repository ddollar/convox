data "http" "releases" {
  url = "https://api.github.com/repos/${var.image}/releases/latest"
}

locals {
  current = jsondecode(data.http.releases.body).tag_name
  release = coalesce(var.release, local.current)
}

provider "helm" {
  kubernetes {
    config_paths = split(":", var.kubeconfig)
  }
}


provider "kubernetes" {
  experiments { manifest_resource = true }

  config_paths = split(":", var.kubeconfig)
}

module "cert-manager" {
  source = "../../cert-manager"

  providers = {
    kubernetes = kubernetes
    helm       = helm
  }
}

module "rack" {
  source = "../../rack/metal"

  providers = {
    kubernetes = kubernetes
    helm       = helm
  }

  domain        = var.domain
  image         = var.image
  name          = var.name
  release       = local.release
  registry_disk = var.registry_disk
  syslog        = var.syslog
  whitelist     = split(",", var.whitelist)
}

