# nxlog-assignment

This repository demonstrates a simple setup for CI/CD using GitHub Actions for CI and Argo CD Image Updater for CD. It incorporates core principles for a production-ready strategy, though this implementation is not production-ready (e.g., lacks security hardening and scalability).

## Overview
- **CI**: Handled via GitHub Actions, triggered by changes in the `app/` directory on the `main` branch.
- **CD**: Managed by Argo CD Image Updater, which automatically updates image digests in GitOps manifests.
- **Application**: A simple app that returns all defined environment variables, located in `app/`.
- **Helm Chart**: Used to render Kubernetes manifests and update the Kustomize base in `gitops/base/`.
- **Infrastructure**: Provisioned with Terraform on a Kind cluster, including Argo CD and Argo CD Image Updater.

## Directory Structure
- `app/`: Application code. Changes here on `main` trigger the CI workflow.
- `helm/`: Helm chart for rendering Kubernetes manifests.
- `gitops/`: GitOps manifests (base and overlays for dev/prod).
- `setup/`: Terraform configuration for infrastructure.

## CI Workflow
The GitHub Actions workflow (`.github/workflows/ci.yaml`) builds and pushes a Docker image:
- **Trigger**: Pushes to `main` branch with changes in `app/**` (recursive).
- **Image**: Built from `app/Dockerfile` and tagged as `${DOCKERHUB_USERNAME}/internal-service:latest`.
- **Secrets**: Uses `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` for Docker Hub login.

## Rendering Manifests
To render Kubernetes manifests from the Helm chart and update the Kustomize base:
```bash
helm template helm/ > gitops/base/config.yaml
```

## Infrastructure Setup
Prerequisites: Install [Terraform](https://www.terraform.io/downloads.html) and [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/).

1. Apply Terraform configuration to create a Kind cluster (1 control plane + 3 worker nodes), install Argo CD and Argo CD Image Updater, and set up dev/prod applications:
   ```bash
   terraform -chdir=setup apply -auto-approve
   ```

2. Set the kubeconfig to target the new cluster:
   ```bash
   export KUBECONFIG=setup/kubeconfig
   ```

## Configuring GitHub Credentials
Argo CD Image Updater requires credentials to push updates to this repository. Create a Kubernetes secret with a GitHub Personal Access Token (PAT) provided via email (with read/write access to repo contents):

```bash
kubectl create secret generic github \
  --namespace argocd \
  --from-literal=username=gothicfann \
  --from-literal=password=<ACCESS_TOKEN_PROVIDED_BY_MAIL>
```

## Accessing Argo CD UI
Forward the Argo CD server port:
```bash
kubectl port-forward -n argocd service/argocd-server 8081:80
```

- Access the UI at: http://localhost:8081
- Login credentials:
  - Username: `admin`
  - Password: `admin`

## Accessing the Demo Application
To access the demo application in the dev environment:
```bash
kubectl port-forward -n dev services/internal-service 8080:8080
```

- Access the app at: http://localhost:8080/

## Environment Sync Policies
- **Dev**: Automatic sync enabled (prune and self-heal).
- **Prod**: Manual sync required (use Argo CD UI or CLI: `argocd app sync prod`).

## Image Update Strategy
- Images are always tagged with `:latest` in CI.
- Argo CD Image Updater uses the `digest` strategy to detect changes (via SHA256 digest) and updates the `kustomization.yaml` in GitOps overlays (dev/prod) with pinned digests for immutability.

## Notes
- Docker Hub rate limits might occur when pulling images.