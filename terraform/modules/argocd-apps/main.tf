resource "kubernetes_manifest" "crewmeister_helm_params" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "crewmeister-challenge"
      namespace = "argocd"
    }
    spec = {
      source = {
        helm = {
          parameters = [
            {
              name  = "keyVault.workloadIdentityClientId"
              value = var.app_identity_client_id
            }
          ]
        }
      }
    }
  }
  field_manager {
    name            = "terraform-helm-params"
    force_conflicts = true
  }
}

resource "kubernetes_manifest" "root_app" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "root-app"
      namespace = "argocd"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.repo_url
        targetRevision = "HEAD"
        path           = "argocd/apps"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "argocd"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
      }
    }
  }
}
