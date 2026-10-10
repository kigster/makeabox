# ------------------------------------------------------------------------------
# APIs & Networking
# ------------------------------------------------------------------------------
resource "google_project_service" "services" {
  for_each = toset([
    "run.googleapis.com",
    "sqladmin.googleapis.com",
    "redis.googleapis.com",
    "compute.googleapis.com",
    "vpcaccess.googleapis.com",
    "secretmanager.googleapis.com",
    "iamcredentials.googleapis.com"
  ])
  service            = each.key
  disable_on_destroy = false
}

resource "google_compute_network" "main" {
  name                    = "makeabox-vpc-${var.environment}"
  auto_create_subnetworks = true
  depends_on              = [google_project_service.services]
}

# Both Cloud Run services run as the default compute service account.
data "google_project" "current" {
  project_id = var.project_id
}

locals {
  runtime_service_account = "${data.google_project.current.number}-compute@developer.gserviceaccount.com"
}

# ------------------------------------------------------------------------------
# Database (Cloud SQL - PostgreSQL)
# ------------------------------------------------------------------------------

# Alphanumeric only: the password is interpolated into ERB-generated YAML in
# config/database.yml, where characters like #, &, *, or {} are YAML syntax.
# 32 alphanumeric characters carry ~190 bits of entropy — plenty.
resource "random_password" "db_password" {
  length  = 32
  special = false
}

resource "google_sql_database_instance" "postgres" {
  name             = "makeabox-db-${var.environment}"
  database_version = "POSTGRES_18"
  region           = var.region

  settings {
    tier    = "db-f1-micro" # Smallest instance for simplicity; scale up as needed
    edition = "ENTERPRISE"  # db-f1-micro is invalid under the ENTERPRISE_PLUS default
    ip_configuration {
      ipv4_enabled = true # Cloud Run connects natively via Cloud SQL proxy securely
    }
  }
  deletion_protection = var.deletion_protection
  depends_on          = [google_project_service.services]
}

resource "google_sql_database" "database" {
  name     = var.db_name
  instance = google_sql_database_instance.postgres.name
}

resource "google_sql_user" "user" {
  name     = "makeabox_user"
  instance = google_sql_database_instance.postgres.name
  password = random_password.db_password.result
}

# ------------------------------------------------------------------------------
# Database password lives in Secret Manager; Cloud Run mounts it as DB_PASSWORD.
# The password never appears in a container env value or the Cloud Console.
# (It is still present in Terraform state — keep the state bucket private.)
# ------------------------------------------------------------------------------
resource "google_secret_manager_secret" "db_password" {
  secret_id = "db-password-${var.environment}"
  replication {
    auto {}
  }
  depends_on = [google_project_service.services]
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}

resource "google_secret_manager_secret_iam_member" "db_password_access" {
  secret_id = google_secret_manager_secret.db_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${local.runtime_service_account}"
}

# The Rails master key secret is created outside Terraform; grant access by name.
resource "google_secret_manager_secret_iam_member" "master_key_access" {
  secret_id = "projects/${var.project_id}/secrets/${var.rails_master_key_secret_name}"
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${local.runtime_service_account}"
}

# ActiveStorage signs GCS URLs through the IAM signBlob API (storage.yml
# sets iam: true because Cloud Run's metadata credential carries no private
# key); the runtime SA must be allowed to sign as itself.
resource "google_service_account_iam_member" "runtime_self_signer" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${local.runtime_service_account}"
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${local.runtime_service_account}"
}

# Required for the Cloud SQL volume mounts on both services.
resource "google_project_iam_member" "cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${local.runtime_service_account}"
}

# ------------------------------------------------------------------------------
# Active Storage uploads (logos, avatars). Cloud Run filesystems are ephemeral
# and per-container, so the Disk service cannot work — files must live in GCS.
# ------------------------------------------------------------------------------
resource "google_storage_bucket" "uploads" {
  name                        = "${var.project_id}-avatars"
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_storage_bucket_iam_member" "uploads_admin" {
  bucket = google_storage_bucket.uploads.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${local.runtime_service_account}"
}

# ------------------------------------------------------------------------------
# Redis (Memorystore)
# ------------------------------------------------------------------------------
resource "google_redis_instance" "cache" {
  name               = "makeabox-redis-${var.environment}"
  memory_size_gb     = 1 # Smallest tier
  region             = var.region
  authorized_network = google_compute_network.main.id
  redis_version      = "REDIS_7_2"
  depends_on         = [google_project_service.services]
}

# ------------------------------------------------------------------------------
# Resolve the :latest tag to its current digest at plan time. Cloud Run pins
# image digests per revision, so deploying by tag alone never rolls a new
# revision. By referencing the digest, every `terragrunt apply` after a
# `just gcp-docker-push` deploys the newly pushed image — and the plan diff
# shows exactly which digest goes live.
# ------------------------------------------------------------------------------
data "google_artifact_registry_docker_image" "app" {
  project       = var.project_id
  location      = var.region
  repository_id = "makeabox-app"
  image_name    = "makeabox-app:latest"
}

# ------------------------------------------------------------------------------
# Web Application (Cloud Run - Puma)
# ------------------------------------------------------------------------------
resource "google_cloud_run_v2_service" "web" {
  name     = "makeabox-web-${var.environment}"
  location = var.region

  # Allow terraform to replace the service (e.g. when tainted). This gates
  # only `terraform destroy` of the resource, not runtime behavior; the
  # database keeps its own deletion protection via var.deletion_protection.
  deletion_protection = false
  template {
    scaling {
      min_instance_count = 1
    }

    containers {
      image = data.google_artifact_registry_docker_image.app.self_link

      # Request-billed CPU (the default) is right for the web tier; the boost
      # speeds up Rails boot on cold starts.
      resources {
        cpu_idle          = true
        startup_cpu_boost = true
        limits = {
          cpu    = "1"
          memory = "1Gi"
        }
      }

      env {
        name  = "RAILS_ENV"
        value = var.rails_env
      }

      # Cloud Run native secret integration
      env {
        name = "RAILS_MASTER_KEY"
        value_source {
          secret_key_ref {
            secret  = var.rails_master_key_secret_name
            version = "latest"
          }
        }
      }

      # Discrete DB_* variables consumed by config/database.yml, which connects
      # through the Cloud SQL Auth Proxy UNIX socket mounted below. Do NOT set
      # DATABASE_URL here: Rails prefers it over database.yml, and a TCP URL
      # would silently bypass the socket configuration.
      env {
        name  = "DB_NAME"
        value = google_sql_database.database.name
      }
      env {
        name  = "DB_USER"
        value = google_sql_user.user.name
      }
      env {
        name = "DB_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.db_password.secret_id
            version = "latest"
          }
        }
      }
      env {
        name  = "CLOUD_SQL_CONNECTION_NAME"
        value = google_sql_database_instance.postgres.connection_name
      }
      env {
        name  = "STORAGE_BUCKET"
        value = google_storage_bucket.uploads.name
      }
      env {
        name  = "GOOGLE_CLOUD_PROJECT"
        value = var.project_id
      }
      env {
        name  = "REDIS_URL"
        value = "redis://${google_redis_instance.cache.host}:${google_redis_instance.cache.port}"
      }

      # Mount Cloud SQL proxy seamlessly
      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }
    }

    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.postgres.connection_name]
      }
    }

    vpc_access {
      network_interfaces {
        network = google_compute_network.main.id
      }
      egress = "PRIVATE_RANGES_ONLY" # Allows connection to Redis
    }
  }

  depends_on = [
    google_secret_manager_secret_version.db_password,
    google_secret_manager_secret_iam_member.db_password_access,
    google_secret_manager_secret_iam_member.master_key_access,
    google_project_iam_member.cloudsql_client
  ]
}

# Make Web public
resource "google_cloud_run_service_iam_member" "public" {
  location = google_cloud_run_v2_service.web.location
  service  = google_cloud_run_v2_service.web.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# ------------------------------------------------------------------------------
# Background Worker (Cloud Run worker pool - Sidekiq)
#
# A worker POOL, not a service: Sidekiq listens on no port, so a Cloud Run
# service's startup probe on $PORT can never pass. Worker pools have no
# probes and no ingress; CPU is always allocated and instances are counted
# manually — exactly the shape a queue consumer needs.
# ------------------------------------------------------------------------------
resource "google_cloud_run_v2_worker_pool" "worker" {
  name                = "makeabox-sidekiq-${var.environment}"
  location            = var.region
  deletion_protection = false
  launch_stage        = "BETA"

  scaling {
    manual_instance_count = 1
  }

  template {
    containers {
      image = data.google_artifact_registry_docker_image.app.self_link

      # Overriding the default Puma command to run Sidekiq instead
      command = ["bundle", "exec", "sidekiq"]

      # Sized for the screenshot renderer. Sidekiq runs concurrency 4, and the
      # per-site lock only stops one SITE being photographed twice at once, so
      # the worst case is four Chromium processes plus Rails. Chromium peaks
      # around 500 MiB on a heavy marketing page; 1 GiB could not hold one of
      # them beside Rails, which is why screenshots were disabled here at all.
      #
      # An OOM in a worker pool kills every job in flight, not the one that
      # caused it, so this is deliberately roomy rather than the smallest thing
      # that fits.
      resources {
        limits = {
          cpu    = "2"
          memory = "4Gi"
        }
      }

      env {
        name  = "RAILS_ENV"
        value = var.rails_env
      }

      # Cloud Run native secret integration
      env {
        name = "RAILS_MASTER_KEY"
        value_source {
          secret_key_ref {
            secret  = var.rails_master_key_secret_name
            version = "latest"
          }
        }
      }

      # Same DB_* wiring as the web service — see the comment there.
      env {
        name  = "DB_NAME"
        value = google_sql_database.database.name
      }
      env {
        name  = "DB_USER"
        value = google_sql_user.user.name
      }
      env {
        name = "DB_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.db_password.secret_id
            version = "latest"
          }
        }
      }
      env {
        name  = "CLOUD_SQL_CONNECTION_NAME"
        value = google_sql_database_instance.postgres.connection_name
      }
      env {
        name  = "STORAGE_BUCKET"
        value = google_storage_bucket.uploads.name
      }
      env {
        name  = "GOOGLE_CLOUD_PROJECT"
        value = var.project_id
      }
      env {
        name  = "REDIS_URL"
        value = "redis://${google_redis_instance.cache.host}:${google_redis_instance.cache.port}"
      }

      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }
    }

    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.postgres.connection_name]
      }
    }

    vpc_access {
      network_interfaces {
        network = google_compute_network.main.id
      }
      egress = "PRIVATE_RANGES_ONLY"
    }
  }

  depends_on = [
    google_secret_manager_secret_version.db_password,
    google_secret_manager_secret_iam_member.db_password_access,
    google_secret_manager_secret_iam_member.master_key_access,
    google_project_iam_member.cloudsql_client
  ]
}

# ------------------------------------------------------------------------------
# DNS / SSL: map the custom domain to the web service. Google provisions and
# renews the managed TLS certificate automatically once DNS points at the
# records surfaced in the `domain_dns_records` output. Requires the domain to
# be verified by the identity running Terraform (gcloud domains verify).
# ------------------------------------------------------------------------------
resource "google_cloud_run_domain_mapping" "web_domain" {
  count    = var.domain == "" ? 0 : 1
  location = var.region
  name     = var.domain

  metadata {
    namespace = var.project_id
  }

  spec {
    # Must match the name of the Cloud Run service resource
    route_name = google_cloud_run_v2_service.web.name
  }
}
