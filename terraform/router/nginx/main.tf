resource "helm_release" "ingress-nginx" {
  name       = "router"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = var.namespace
  wait       = true

  values = [yamlencode({
    "controller" = {
      "labels" = {
        app     = "system"
        name    = "router"
        rack    = var.rack
        system  = "convox"
        service = "router"
        type    = "service"
      }
      "service" = {
        "enabled" = false
      }
    }
  })]
}
