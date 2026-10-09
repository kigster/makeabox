# ------------------------------------------------------------------------------
# Stripe webhook endpoint
#
# Declared in its own terragrunt unit rather than inside gcp_stack, so that
# applying GCP infrastructure never requires a Stripe API key, and rotating a
# Stripe key never plans a change against Cloud Run or Cloud SQL.
#
# Provider choice: stripe/stripe is Stripe's OFFICIAL provider. The widely
# referenced lukasaron/stripe was archived by its author on 2026-04-17 with a
# README pointing here; franckverrot/stripe and andrewbaxter/stripe are both
# dormant AND fail to mark the signing secret as sensitive, which would print
# whsec_… in plaintext plan output and CI logs.
#
# Pin >= 0.2.3: that is the first stable release in which `secret` is marked
# Sensitive.
# ------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.5"

  required_providers {
    stripe = {
      source  = "stripe/stripe"
      version = "~> 0.2.3"
    }
  }
}

resource "stripe_webhook_endpoint" "billing" {
  url            = var.webhook_url
  description    = var.description
  enabled_events = var.enabled_events

  metadata = {
    managed_by = "terraform"
    module     = "iac/modules/stripe_webhook"
    env        = var.environment
  }

  # api_version is deliberately NOT set. The provider validates it against a
  # hardcoded allowlist whose newest entry is 2025-11-17.clover, so naming the
  # 2026-06-24.dahlia version this app pins in config/initializers/stripe.rb
  # fails at plan time. Omitted, the endpoint follows the account default.
}
