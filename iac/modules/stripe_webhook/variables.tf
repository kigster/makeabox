variable "webhook_url" {
  type        = string
  description = "Absolute URL Stripe POSTs events to, e.g. https://makeabox.at/stripe/webhooks"
}

variable "enabled_events" {
  type        = list(string)
  description = <<-EOT
    Stripe event types the endpoint subscribes to.

    Do NOT hand-write this list. It is THE list, and it lives in
    config/stripe/enabled_events.json so that Ruby (StripeMirror::EnabledEvents)
    and Terraform read the same file. The terragrunt unit passes it as:

      jsondecode(file("<repo>/config/stripe/enabled_events.json")).events

    Never "*": a wildcard re-admits every radar.*, balance.* and payout.* event
    into the raw log, which is the noise this list exists to exclude.
  EOT

  validation {
    condition     = !contains(var.enabled_events, "*")
    error_message = "enabled_events must enumerate types explicitly; \"*\" defeats the purpose of the list."
  }

  validation {
    condition     = length(var.enabled_events) > 0
    error_message = "enabled_events must not be empty."
  }
}

variable "description" {
  type        = string
  default     = "makeabox.at — billing event ingestion (managed by Terraform)"
  description = "Human-readable label shown in the Stripe dashboard's webhook list."
}

variable "environment" {
  type        = string
  description = "Environment tag recorded in Stripe metadata, e.g. prod or staging."
}
