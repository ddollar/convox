provider "digitalocean" {
  spaces_access_id  = var.access_id
  spaces_secret_key = var.secret_key
}

provider "kubernetes" {
  experiments { manifest_resource = true }

  cluster_ca_certificate = module.cluster.ca
  host                   = module.cluster.endpoint
  token                  = module.cluster.token
}

data "http" "releases" {
  url = "https://api.github.com/repos/${var.image}/releases/latest"
}

locals {
  current = jsondecode(data.http.releases.body).tag_name
  release = coalesce(var.release, local.current)
}

module "cert-manager" {
  source = "../../cert-manager"

  providers = {
    kubernetes = kubernetes
    helm       = helm
  }
}

module "cluster" {
  source = "../../cluster/do"

  providers = {
    digitalocean = digitalocean
  }

  name      = var.name
  node_type = var.node_type
  region    = var.region
}

module "rack" {
  source = "../../rack/do"

  providers = {
    digitalocean = digitalocean
    kubernetes   = kubernetes
  }

  access_id     = var.access_id
  cluster       = module.cluster.id
  image         = var.image
  name          = var.name
  region        = var.region
  registry_disk = var.registry_disk
  release       = local.release
  secret_key    = var.secret_key
  syslog        = var.syslog
  whitelist     = split(",", var.whitelist)
}
