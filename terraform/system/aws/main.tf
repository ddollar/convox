provider "aws" {
  region = var.region
}

provider "kubernetes" {
  experiments { manifest_resource = true }

  cluster_ca_certificate = module.cluster.ca
  host                   = module.cluster.endpoint
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    cluster_ca_certificate = module.cluster.ca
    host                   = module.cluster.endpoint
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.cluster.id
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
  source = "../../cluster/aws"

  providers = {
    aws = aws
  }

  availability_zones = var.availability_zones
  cidr               = var.cidr
  name               = var.name
  node_disk          = var.node_disk
  node_type          = var.node_type
  private            = var.private
}

module "rack" {
  source = "../../rack/aws"

  providers = {
    aws        = aws
    helm       = helm
    kubernetes = kubernetes
  }

  cluster      = module.cluster.id
  idle_timeout = var.idle_timeout
  image        = var.image
  name         = var.name
  oidc_arn     = module.cluster.oidc_arn
  oidc_sub     = module.cluster.oidc_sub
  release      = local.release
  subnets      = module.cluster.subnets
  whitelist    = split(",", var.whitelist)
}
