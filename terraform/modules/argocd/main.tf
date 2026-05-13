resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_version
  namespace        = "argocd"
  create_namespace = true

  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }
  set {
    name  = "server.ingress.enabled"
    value = "false"
  }
  # AppGW terminates SSL; ArgoCD serves plain HTTP on the backend
  set {
    name  = "configs.params.server\\.insecure"
    value = "true"
  }
}
