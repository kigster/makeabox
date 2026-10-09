# GCP Rails Deployment & Terragrunt Troubleshooting Summary

This document summarizes the deployment and troubleshooting steps for containerizing a Ruby on Rails application, deploying it to Google Cloud, and managing the infrastructure using Terragrunt and Terraform.

______________________________________________________________________

## 1. Pushing the Docker Image to Google Artifact Registry (GAR)

To deploy the Rails app, the local Docker image must be pushed to a repository in Google Artifact Registry.

**Steps:**

1. **Authenticate the Google Cloud CLI:** Ensure you are logged into the correct project.
   ```bash
   gcloud auth login
   gcloud config set project qualifiedat-production
   ```
1. **Configure Docker Auth:** Configure the Docker client to use `gcloud` as a credential helper for the specific region (`us-central1`).
   ```bash
   gcloud auth configure-docker us-central1-docker.pkg.dev
   ```
1. **Tag the Image:** Tag the local image with the exact remote path of the GAR repository.
   ```bash
   docker tag my-local-app us-central1-docker.pkg.dev/qualifiedat-production/qualified-app/qualified-app:latest
   ```
1. **Push the Image:** Upload the image to Google Cloud.
   ```bash
   docker push us-central1-docker.pkg.dev/qualifiedat-production/qualified-app/qualified-app:latest
   ```

______________________________________________________________________

## 2. Connecting Rails to Cloud SQL Securely

To securely connect the containerized Rails application to Cloud SQL, the Cloud SQL Auth Proxy is used, which communicates via a UNIX socket.

**Configuration in Rails (`config/database.yml`):** Instead of using an IP address, the host is mapped to the UNIX socket directory mounted by the Auth Proxy.

```yaml
production:
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  database: <%= ENV['DB_NAME'] %>
  username: <%= ENV['DB_USER'] %>
  password: <%= ENV['DB_PASSWORD'] %>
  host: <%= ENV['DB_SOCKET_DIR'] || '/cloudsql' %>/<%= ENV['CLOUD_SQL_CONNECTION_NAME'] %>
```

**Required Environment Variables:**

- `DB_NAME`, `DB_USER`, `DB_PASSWORD`
- `CLOUD_SQL_CONNECTION_NAME` (Format: `project-id:region:instance-name`)

**IAM Permissions:** The Compute Service Account running the container (e.g., Cloud Run default service account) must have the **Cloud SQL Client** (`roles/cloudsql.client`) role.

______________________________________________________________________

## 3. Injecting the Rails Master Key via Secret Manager

To avoid committing the `rails_master_key` to plaintext Terraform state, the key should be injected securely using Google Secret Manager at runtime.

**Terraform Implementation (Cloud Run Native Secret Integration):** Pass the *Secret Name* (not the key itself) via Terragrunt `inputs`, and configure the Terraform module to mount the secret as an environment variable in Cloud Run.

```terraform
# inside your cloud run resource declaration
env {
  name = "RAILS_MASTER_KEY"
  value_source {
    secret_key_ref {
      secret  = var.rails_master_key_secret_name
      version = "latest" 
    }
  }
}
```

______________________________________________________________________

## 4. Fixing Terragrunt Initialization Issues (`terragrunt init`)

During infrastructure initialization, two distinct issues were encountered and resolved.

**Issue 1: Missing State Bucket (Fatal Error)**

- **Error:** `storage: bucket doesn't exist: googleapi: Error 404`
- **Cause:** The Google Cloud Storage (GCS) bucket configured to hold the `terraform.tfstate` file did not exist yet.
- **Fix:** Rerun the init command with the backend bootstrap flag to allow Terragrunt to auto-create the bucket.
  ```bash
  terragrunt init --backend-bootstrap
  ```

**Issue 2: Root Naming Anti-Pattern (Warning)**

- **Warning:** `Using terragrunt.hcl as the root of Terragrunt configurations is an anti-pattern...`
- **Fix:** Rename the parent configuration file from `terragrunt.hcl` to `root.hcl`, and update the child `terragrunt.hcl` files to reference `root.hcl` in the `include` block.

______________________________________________________________________

## 5. Fixing Terraform Prompting for Variables (`terragrunt apply`)

- **Issue:** The deployment paused and prompted for manual input: `var.rails_master_key Enter a value:`
- **Cause:** A variable was declared in the Terraform module's `variables.tf`, but a matching value was missing from the `terragrunt.hcl` `inputs` block.
- **Fix:** Canceled the run (`Ctrl + C`) and ensured that `variables.tf` and the `inputs = {}` block in `terragrunt.hcl` were fully aligned (e.g., replacing `rails_master_key` with `rails_master_key_secret_name` in `variables.tf`).

______________________________________________________________________

## 6. Fixing Cloud SQL Edition & Tier Mismatch

- **Error:** `Invalid Tier (db-f1-micro) for (ENTERPRISE_PLUS) Edition.`
- **Cause:** Attempting to provision a small, shared-core machine type (`db-f1-micro`) under the high-performance `ENTERPRISE_PLUS` database edition, which strictly requires dedicated performance tiers.
- **Fix:** Adjusted the Cloud SQL resource block in Terraform to match a valid configuration.
  - *For a cost-effective setup:* Downgrade the `edition` setting to `"ENTERPRISE"` while keeping the tier as `db-f1-micro`.
  - *For high availability/production:* Keep `"ENTERPRISE_PLUS"` but upgrade the `tier` to a supported size like `"db-perf-optimized-N-2"`.

______________________________________________________________________

## 7. The Stripe webhook endpoint (`iac/envs/prod/stripe`)

- **What it is:** a terragrunt unit separate from `envs/prod`, declaring the Stripe webhook endpoint with the official `stripe/stripe` provider. It is deliberately not part of `gcp_stack`: applying GCP infrastructure must never require a Stripe API key, and a Stripe change must never plan against Cloud Run or Cloud SQL.
- **It does not `include "root"`.** `root.hcl` generates a `provider "google"` block wired to `var.project_id`/`var.region`, which this module does not declare, and Terragrunt refuses two `generate` blocks that share a name — so the GCP provider cannot be overridden from the child. The unit carries its own `remote_state` block with its own state prefix instead.
- **Credentials:** `STRIPE_API_KEY` must be in the environment for `terragrunt plan`/`apply`.
- **Where the signing secret lives, which was documented nowhere until now:** the Stripe `whsec_…` webhook signing secret rides in `config/credentials/production.yml.enc`, unlocked at runtime by `RAILS_MASTER_KEY`. It is **not** in Secret Manager, unlike the master key itself. `config/initializers/stripe.rb` reads it into `Rails.application.config.x.stripe_webhook_secret`; if it is absent the webhook endpoint answers 503 and billing degrades gracefully.
- **Do not `terraform import` the existing dashboard-created endpoint.** Stripe returns the signing secret only at creation, so an imported resource has a permanently empty `secret` attribute. See `iac/modules/stripe_webhook/README.md` for the cutover procedure.

### Pre-deploy check: `CREATE SCHEMA`

The Stripe mirror lives in a second Postgres schema, created by migration `20260801000000`. **Confirm the Cloud SQL application role holds `CREATE ON DATABASE` before deploying**, in a maintenance window rather than during a deploy:

```bash
bin/rails stripe:preflight   # with DATABASE_URL pointed at the production database
```

If it reports `CREATE ON DATABASE: NO`, a superuser must run the `GRANT` the task prints. This has been verified locally, not against Cloud SQL.

### PostgreSQL client in the runtime image

`schema_format = :sql` means `db/structure.sql` is loaded with `psql`, and `bin/docker-entrypoint` runs `rails db:prepare` on boot. The Dockerfile therefore installs `postgresql-client-18` from PGDG — matching the Cloud SQL `POSTGRES_18` server major version. Against an existing database `db:prepare` only migrates (and `dump_schema_after_migration` is `false` in production, so `pg_dump` is not invoked), but against an empty one it is a `structure.sql` load and would fail without the client.
