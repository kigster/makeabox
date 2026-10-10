# The Stripe webhook endpoint, as a unit of its own.
#
# This unit deliberately does NOT `include "root"`. root.hcl generates a
# `provider "google"` block wired to var.project_id and var.region, which this
# module does not declare, and Terragrunt refuses two generate blocks sharing a
# name — so the GCP provider cannot simply be overridden. Being separate is the
# point anyway: applying GCP infrastructure must never require a Stripe API key,
# and a Stripe change must never plan against Cloud Run or Cloud SQL.
#
# The backend below mirrors root.hcl's, with its own state prefix.

terraform {
  source = "../../../modules/stripe_webhook"
}

remote_state {
  backend = "gcs"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    project  = "makeabox-production"
    location = "us-central1"
    bucket   = "makeabox-at-tf-state-prod"
    prefix   = "envs/prod/stripe/terraform.tfstate"
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
# Reads STRIPE_API_KEY from the environment. Never commit a key here.
provider "stripe" {}
EOF
}

inputs = {
  webhook_url = "https://makeabox.io/stripe/webhooks"
  environment = "prod"

  # THE list. Read from the same file StripeMirror::EnabledEvents reads, so the
  # subscription and the projectors can never drift apart.
  enabled_events = jsondecode(file("${get_repo_root()}/config/stripe/enabled_events.json")).events
}
