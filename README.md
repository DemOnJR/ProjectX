# ProjectX

ProjectX contains the application source code and the Terraform infrastructure used to create the GCP foundation for the app.

The GitOps repository is expected to live separately in `../ProjectX-ArgoCD`.

## What Terraform Creates

- GCP APIs required for GKE and Artifact Registry
- VPC with secondary ranges for GKE pods and services
- Artifact Registry Docker repository
- Regional GKE cluster with cluster autoscaling and node pool autoscaling
- Metrics Server via GKE system components
- Argo CD installed with Helm
- An Argo CD `Application` that points at the GitOps repository

## Local App

Run the API locally:

```bash
cd app
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Open `http://localhost:8000`.

## Build And Push Image

Replace the project ID and region as needed:

```bash
export PROJECT_ID="my-gcp-project"
export REGION="europe-west3"
export IMAGE="$REGION-docker.pkg.dev/$PROJECT_ID/projectx/projectx-api:0.1.0"

gcloud auth configure-docker "$REGION-docker.pkg.dev"
docker build -t "$IMAGE" ./app
docker push "$IMAGE"
```

Then update `../ProjectX-ArgoCD/apps/projectx-api/values.yaml` with the new image tag and commit/push the GitOps repository.

## Terraform

Create your variable file:

```bash
cp infra/terraform/terraform.tfvars.example infra/terraform/terraform.tfvars
```

Edit `infra/terraform/terraform.tfvars`, then run:

```bash
cd infra/terraform
export VAULT_TOKEN="..."   # required when write_ci_secrets_to_vault is true (CI secrets → Vault KV)
terraform init
terraform plan
terraform apply
```

If your state still contains legacy `github_actions_secret.*` from an older revision, remove them from Terraform state once (`terraform state rm '<address>'`) so the plan does not reference the removed GitHub provider.

### CI secrets (Vault + GitHub Actions)

- `infra/terraform/vault-ci.tf` writes CI fields to Vault KV v2 at `kv/data/ci/projectx` (keys: `wif_provider`, `gcp_service_account`, `gcp_project_id`, `registry`, `gitops_pat`, `app_url`, `gcp_cluster_name`, `gcp_region`).
- `infra/terraform-vault/github-jwt.tf` enables JWT auth for GitHub OIDC so workflows can read that path.
- In the **ProjectX** GitHub repo, add Actions **Secrets** (not Variables) so values are **redacted in logs**: `VAULT_ADDR`, `VAULT_JWT_PATH` (e.g. `jwt-github`), `VAULT_JWT_ROLE` (e.g. `github-ci-projectx`), `VAULT_CI_SECRET_PATH` (`kv/data/ci/projectx`).
- Apply `infra/terraform-vault` after the cluster exists so the JWT mount and role are present.

After apply, connect to the cluster:

```bash
gcloud container clusters get-credentials projectx-gke --region europe-west3 --project "$PROJECT_ID"
```

Get the initial Argo CD admin password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d && echo
```

Access Argo CD locally:

```bash
kubectl -n argocd port-forward svc/argocd-server 8080:80
```

Open `http://localhost:8080`.
