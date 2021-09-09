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

module "platform" {
  source = "../../platform"
}

module "cert-manager" {
  source = "../../cert-manager"

  providers = {
    kubernetes = kubernetes
    helm       = helm
  }
}

module "rack" {
  source = "../../rack/local"

  providers = {
    kubernetes = kubernetes
  }

  image    = var.image
  name     = var.name
  platform = module.platform.name
  release  = local.release
}
