data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  tags = {
    System = "convox"
    Rack   = var.name
  }
}

resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki-stack"
  namespace  = var.namespace

  set {
    name  = "loki.persistence.enabled"
    value = "true"
  }

  set {
    name  = "loki.persistence.size"
    value = "1Gi"
  }
}


module "k8s" {
  source = "../k8s"

  providers = {
    kubernetes = kubernetes
  }

  domain    = var.domain
  image     = var.image
  namespace = var.namespace
  rack      = var.name
  release   = var.release
  resolver  = var.resolver

  annotations = {
    "cert-manager.io/cluster-issuer" = "letsencrypt"
    "eks.amazonaws.com/role-arn"     = aws_iam_role.api.arn
    "iam.amazonaws.com/role"         = aws_iam_role.api.arn
    "kubernetes.io/ingress.class"    = "nginx"
  }

  env = {
    AWS_REGION = data.aws_region.current.name
    BUCKET     = aws_s3_bucket.storage.id
    LOKI_URL   = "http://loki.${var.namespace}.svc.cluster.local:3100"
    PROVIDER   = "aws"
    RESOLVER   = var.resolver
    ROUTER     = var.router
    SOCKET     = "/var/run/docker.sock"
  }
}
