provider "azurerm" {
  features {}
}

provider "kubernetes" {
  experiments { manifest_resource = true }

  client_certificate     = module.cluster.client_certificate
  client_key             = module.cluster.client_key
  cluster_ca_certificate = module.cluster.ca
  host                   = module.cluster.endpoint
}

data "http" "releases" {
  url = "https://api.github.com/repos/${var.image}/releases/latest"
}

locals {
  current = jsondecode(data.http.releases.body).tag_name
  release = coalesce(var.release, local.current)
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rack" {
  name     = var.name
  location = var.region
}


module "cert-manager" {
  source = "../../cert-manager"

  providers = {
    kubernetes = kubernetes
    helm       = helm
  }
}

module "cluster" {
  source = "../../cluster/azure"

  providers = {
    azurerm = azurerm
  }

  name           = var.name
  node_type      = var.node_type
  region         = var.region
  resource_group = azurerm_resource_group.rack.id
}

module "rack" {
  source = "../../rack/azure"

  providers = {
    azurerm    = azurerm
    kubernetes = kubernetes
  }

  cluster        = module.cluster.id
  image          = var.image
  name           = var.name
  region         = var.region
  release        = local.release
  resource_group = azurerm_resource_group.rack.id
  syslog         = var.syslog
  whitelist      = split(",", var.whitelist)
  workspace      = module.cluster.workspace
}
