output "webhook_endpoint_id" {
  description = "Stripe id of the endpoint (we_...). Quote this to Stripe support."
  value       = stripe_webhook_endpoint.billing.id
}

output "webhook_endpoint_status" {
  description = <<-EOT
    "enabled" or "disabled". Stripe publishes no event type for endpoint
    auto-disable — it cannot webhook you to say your webhook is broken — so this
    attribute and `rake stripe:webhook_status` are the only programmatic signals
    that exist. A `terraform refresh` surfaces a Stripe-side disable here.
  EOT
  value       = stripe_webhook_endpoint.billing.status
}

output "webhook_signing_secret" {
  description = <<-EOT
    The whsec_… signing secret, for config/credentials/production.yml.enc.

    Stripe returns this ONLY at creation. `terraform import` of an endpoint
    created in the dashboard yields a managed resource whose `secret` is
    permanently empty — which is why the endpoint must be created by Terraform
    rather than adopted. See README.md.
  EOT
  value       = stripe_webhook_endpoint.billing.secret
  sensitive   = true
}
