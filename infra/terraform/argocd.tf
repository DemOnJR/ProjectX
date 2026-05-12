resource "kubernetes_namespace" "argocd" {
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
  namespace        = kubernetes_namespace.argocd.metadata[0].name
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

resource "kubernetes_namespace" "vault_secrets_operator" {
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
  namespace        = kubernetes_namespace.vault_secrets_operator[0].metadata[0].name
  create_namespace = false
  wait             = true
  timeout          = 600

  depends_on = [kubernetes_namespace.vault_secrets_operator]
}

resource "kubernetes_secret_v1" "argocd_repo" {
  count = local.use_private_gitops ? 1 : 0

  metadata {
    name      = "projectx-gitops-repo"
    namespace = kubernetes_namespace.argocd.metadata[0].name
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

resource "helm_release" "argocd_apps" {
  name             = "argocd-apps"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argocd-apps"
  namespace        = kubernetes_namespace.argocd.metadata[0].name
  create_namespace = false
  wait             = true
  timeout          = 600

  values = [
    yamlencode({
      applications = {
        projectx-api = {
          namespace = kubernetes_namespace.argocd.metadata[0].name
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
            namespace = "projectx"
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
    kubernetes_secret_v1.argocd_repo
  ]
}
