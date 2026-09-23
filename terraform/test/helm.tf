provider "helm" {
  kubernetes {
    host                   = "https://${google_container_cluster.main.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(google_container_cluster.main.master_auth[0].cluster_ca_certificate)
  }
}

provider "kubernetes" {
  host                   = "https://${google_container_cluster.main.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.main.master_auth[0].cluster_ca_certificate)
}

data "google_client_config" "default" {}

# ArgoCD namespace
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }

  depends_on = [
    google_container_node_pool.main,
    google_container_node_pool.tools,
    google_container_node_pool.monitoring
  ]
}

# ArgoCD Helm release
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "10.9.1"
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  values = [
    <<-EOT
    global:
      nodeSelector:
        pool: tools
      tolerations:
        - key: pool
          value: tools
          effect: NoSchedule

    server:
      service:
        type: LoadBalancer

    configs:
      params:
        server.insecure: true

    EOT
  ]

  depends_on = [
    google_container_node_pool.tools,
    kubernetes_namespace.argocd
  ]
}

# ArgoCD Image Updater
resource "helm_release" "argocd_image_updater" {
  name       = "argocd-image-updater"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-image-updater"
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  values = [
    <<-EOT
    config:
      registries:
        - name: GCP Artifact Registry
          prefix: europe-north1-docker.pkg.dev
          api_url: https://europe-north1-docker.pkg.dev
          credentials: ext:/scripts/gcp-auth.sh
          credsexpire: 1h

    authScripts:
      enabled: true
      scripts:
        gcp-auth.sh: |
          #!/bin/sh
          TOKEN=$(wget -qO- \
            --header="Metadata-Flavor: Google" \
            "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token" \
            | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')

          echo "oauth2accesstoken:$TOKEN"
    EOT
  ]

  depends_on = [helm_release.argocd]
}