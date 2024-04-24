provider "kubernetes" {
  config_path    = "~/.kube/homelab"
  config_context = "homelab"
}


resource "kubernetes_secret" "external" {
  metadata {
    name      = var.name
    namespace = var.namespace

    annotations = {
      "app.kubernetes.io/managed-by" = "Terraform"
    }
  }

  data = var.data
}
