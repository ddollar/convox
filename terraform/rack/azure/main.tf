module "k8s" {
  source = "../k8s"

  providers = {
    kubernetes = kubernetes
  }

  domain  = module.router.endpoint
  name    = var.name
  release = var.release
}

module "api" {
  source = "../../api/azure"

  providers = {
    azurerm    = azurerm
    kubernetes = kubernetes
  }

  cluster        = var.cluster
  domain         = module.router.endpoint
  image          = var.image
  name           = var.name
  namespace      = module.k8s.namespace
  region         = var.region
  release        = var.release
  resolver       = module.resolver.endpoint
  resource_group = var.resource_group
  router         = module.router.endpoint
  syslog         = var.syslog
  workspace      = var.workspace
}

module "resolver" {
  source = "../../resolver/azure"

  providers = {
    azurerm    = azurerm
    kubernetes = kubernetes
  }

  image     = var.image
  namespace = module.k8s.namespace
  rack      = var.name
  release   = var.release
}

module "router" {
  source = "../../router/azure"

  providers = {
    azurerm    = azurerm
    kubernetes = kubernetes
  }

  name      = var.name
  namespace = module.k8s.namespace
  region    = var.region
  release   = var.release
  whitelist = var.whitelist
}
