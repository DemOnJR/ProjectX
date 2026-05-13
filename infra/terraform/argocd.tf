resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = "argocd"
  }

  depends_on = [module.gke]
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  namespace        = kubernetes_namespace_v1.argocd.metadata[0].name
  create_namespace = false
  wait             = true
  timeout          = 900

  values = [
    yamlencode({
      server = {
        service = {
          type = "ClusterIP"
        }
      }
    })
  ]
}

# Cloudflare tunnel that exposes Argo CD at argocd.pbcv.dev (or your configured hostname).
resource "kubernetes_secret_v1" "argocd_cloudflared_token" {
  count = var.argocd_tunnel_token != "" ? 1 : 0

  metadata {
    name      = "argocd-cloudflared-token"
    namespace = kubernetes_namespace_v1.argocd.metadata[0].name
  }

  data = {
    token = var.argocd_tunnel_token
  }

  depends_on = [helm_release.argocd]
}

resource "kubernetes_deployment_v1" "argocd_cloudflared" {
  count = var.argocd_tunnel_token != "" ? 1 : 0

  metadata {
    name      = "argocd-cloudflared"
    namespace = kubernetes_namespace_v1.argocd.metadata[0].name
    labels    = { app = "argocd-cloudflared" }
  }

  spec {
    replicas = 2

    selector {
      match_labels = { app = "argocd-cloudflared" }
    }

    template {
      metadata {
        labels = { app = "argocd-cloudflared" }
      }

      spec {
        container {
          name  = "cloudflared"
          image = "cloudflare/cloudflared:2025.11.1"
          args  = ["tunnel", "--no-autoupdate", "--metrics", "0.0.0.0:2000", "run", "--token", "$(TUNNEL_TOKEN)"]

          env {
            name = "TUNNEL_TOKEN"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.argocd_cloudflared_token[0].metadata[0].name
                key  = "token"
              }
            }
          }

          port {
            name           = "metrics"
            container_port = 2000
          }

          liveness_probe {
            http_get {
              path = "/ready"
              port = "metrics"
            }
            initial_delay_seconds = 10
            period_seconds        = 10
          }

          resources {
            requests = { cpu = "50m", memory = "64Mi" }
            limits   = { cpu = "200m", memory = "256Mi" }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_secret_v1.argocd_cloudflared_token]
}

resource "kubernetes_namespace_v1" "vault_secrets_operator" {
  count = var.install_vault_secrets_operator ? 1 : 0

  metadata {
    name = "vault-secrets-operator-system"
  }

  depends_on = [module.gke]
}

resource "helm_release" "vault_secrets_operator" {
  count = var.install_vault_secrets_operator ? 1 : 0

  name             = "vault-secrets-operator"
  repository       = "https://helm.releases.hashicorp.com"
  chart            = "vault-secrets-operator"
  version          = var.vault_secrets_operator_chart_version
  namespace        = kubernetes_namespace_v1.vault_secrets_operator[0].metadata[0].name
  create_namespace = false
  wait             = true
  timeout          = 600

  depends_on = [kubernetes_namespace_v1.vault_secrets_operator]
}

resource "kubernetes_secret_v1" "argocd_repo" {
  count = local.use_private_gitops ? 1 : 0

  metadata {
    name      = "projectx-gitops-repo"
    namespace = kubernetes_namespace_v1.argocd.metadata[0].name
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  type = "Opaque"

  data = {
    type     = "git"
    name     = "projectx-gitops"
    url      = var.gitops_repo_url
    username = var.gitops_repo_username
    password = var.gitops_repo_password
  }

  depends_on = [helm_release.argocd]
}

# Pre-create the projectx namespace so the cloudflare tunnel secret can be injected
# before ArgoCD deploys the app.
resource "kubernetes_namespace_v1" "projectx" {
  metadata {
    name = "projectx"
  }

  depends_on = [module.gke]
}

# Cloudflare tunnel token for the projectx app (used by values.yaml cloudflareTunnel).
resource "kubernetes_secret_v1" "projectx_cloudflared_token" {
  count = var.projectx_tunnel_token != "" ? 1 : 0

  metadata {
    name      = "cloudflared-token"
    namespace = kubernetes_namespace_v1.projectx.metadata[0].name
  }

  data = {
    token = var.projectx_tunnel_token
  }
}

resource "helm_release" "argocd_apps" {
  name             = "argocd-apps"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argocd-apps"
  namespace        = kubernetes_namespace_v1.argocd.metadata[0].name
  create_namespace = false
  wait             = true
  timeout          = 600

  values = [
    yamlencode({
      applications = {
        projectx-api = {
          namespace = kubernetes_namespace_v1.argocd.metadata[0].name
          project   = "default"
          source = {
            repoURL        = var.gitops_repo_url
            targetRevision = var.gitops_target_revision
            path           = var.gitops_app_path
            helm = {
              valueFiles = ["values.yaml"]
            }
          }
          destination = {
            server    = "https://kubernetes.default.svc"
            namespace = kubernetes_namespace_v1.projectx.metadata[0].name
          }
          syncPolicy = {
            automated = {
              prune    = true
              selfHeal = true
            }
            syncOptions = [
              "CreateNamespace=true"
            ]
          }
        }
      }
    })
  ]

  depends_on = [
    helm_release.argocd,
    helm_release.vault_secrets_operator,
    kubernetes_secret_v1.argocd_repo,
    kubernetes_namespace_v1.projectx,
  ]
}
