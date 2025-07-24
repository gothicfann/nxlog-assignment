terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "0.9.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.0.2"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.19.0"
    }
  }
}

provider "kind" {}

resource "kind_cluster" "nxlog-assigntment" {
  name       = "nxlog-assignment"
  node_image = "kindest/node:v1.33.2"
  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"
    node {
      role = "control-plane"
    }
    node {
      role = "worker"
    }
    node {
      role = "worker"
    }
    node {
      role = "worker"
    }
  }

  kubeconfig_path = "${path.root}/kubeconfig"
}

provider "helm" {
  kubernetes = {
    config_path = kind_cluster.nxlog-assigntment.kubeconfig_path
  }
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "8.2.0"
  namespace        = "argocd"
  create_namespace = true

  values = [
    <<-YAML
    configs:
      secret:
        argocdServerAdminPassword: "$2a$10$yFLSTyN5uFzcavEeTadMiOG.jvOh4MzWBgqbQk8OokFjR6khiS7ma"

      params:
        server.insecure: true
    YAML
  ]
}

resource "helm_release" "argocd-image-updater" {
  name             = "argocd-image-updater"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argocd-image-updater"
  version          = "0.12.3"
  namespace        = "argocd"
  create_namespace = true

  values = [
    <<-YAML
    extraArgs:
      - --interval
      - 1m
    config:
      logLevel: "info"
    YAML
  ]
}

provider "kubectl" {
  config_path = kind_cluster.nxlog-assigntment.kubeconfig_path
}

# resource "time_sleep" "wait_30_seconds" {
#   depends_on = [helm_release.argocd]

#   create_duration = "30s"
# }

resource "kubectl_manifest" "dev" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: dev
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
  annotations:
    argocd-image-updater.argoproj.io/image-list: internal-service=docker.io/gothicfan/internal-service:latest
    argocd-image-updater.argoproj.io/internal-service.update-strategy: digest
    argocd-image-updater.argoproj.io/write-back-method: git:secret:argocd/github
    argocd-image-updater.argoproj.io/write-back-target: kustomization
spec:
  project: default
  source:
    repoURL: https://github.com/gothicfann/nxlog-assignment.git
    targetRevision: HEAD
    path: gitops/overlays/dev
  destination:
    server: https://kubernetes.default.svc
    namespace: dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
YAML

  depends_on = [helm_release.argocd]
}


resource "kubectl_manifest" "prod" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: prod
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
  annotations:
    argocd-image-updater.argoproj.io/image-list: internal-service=docker.io/gothicfan/internal-service:latest
    argocd-image-updater.argoproj.io/internal-service.update-strategy: digest    
    argocd-image-updater.argoproj.io/write-back-method: git:secret:argocd/github
    argocd-image-updater.argoproj.io/write-back-target: kustomization
spec:
  project: default
  source:
    repoURL: https://github.com/gothicfann/nxlog-assignment.git
    targetRevision: HEAD
    path: gitops/overlays/prod
  destination:
    server: https://kubernetes.default.svc
    namespace: prod
  syncPolicy:
    syncOptions:
      - CreateNamespace=true
YAML

  depends_on = [helm_release.argocd]
}
