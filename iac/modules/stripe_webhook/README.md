# `stripe_webhook` — the Stripe webhook endpoint, in code

Until this module existed, the Stripe webhook endpoint was invisible to the repository: no Stripe provider in `iac/`, no rake task that created one, and `enabled_events` in no commit on any branch. It was created by hand in the dashboard, which means **its subscription list was unknowable from code** — and if it was created with "all events" (the dashboard default when you click through quickly), the raw event log fills with `radar.*`, `balance.*` and `payout.*` from the first deploy.

This module ends that. It does not, by itself, fix the live endpoint — see [Reconciling the existing endpoint](#reconciling-the-existing-endpoint).

## One list, two consumers

`enabled_events` is **not** written here. It lives in `config/stripe/enabled_events.json` and is read by:

- Ruby — `StripeMirror::EnabledEvents`
- Terraform — the terragrunt unit, via `jsondecode(file(...)).events`

Two copies of a list drift, and a projector with no subscription is dead code while a subscription with no projector is noise. `spec/models/stripe_mirror/enabled_events_spec.rb` asserts that everything the app dispatches on is subscribed.

## Usage

```hcl
terraform {
  source = "../../../modules/stripe_webhook"
}

inputs = {
  webhook_url    = "https://makeabox.io/stripe/webhooks"
  environment    = "prod"
  enabled_events = jsondecode(file("${get_repo_root()}/config/stripe/enabled_events.json")).events
}
```

The provider needs `STRIPE_API_KEY` in the environment. It is required at plan time but is not validated against Stripe until refresh, so a plan for a not-yet-created endpoint succeeds with a dummy key.

## Reconciling the existing endpoint

**Do not `terraform import` the dashboard-created endpoint.** Stripe returns the `whsec_…` signing secret *only at creation*; import produces a managed resource whose `secret` attribute is permanently empty, and there is no API to read it back.

Two options, in order of preference:

1. **Create fresh, cut over, delete old.** `terraform apply` creates a second endpoint at the same URL, `terraform output -raw webhook_signing_secret` gives the new secret, it goes into `config/credentials/production.yml.enc`, the app is deployed, and only then is the old endpoint deleted in the dashboard. Stripe delivers to both endpoints during the overlap, and redelivery is a no-op insert against the unique index on `stripe.events.stripe_event_id` — so a duplicate window is harmless, which is what makes this cutover safe.
1. **Narrow by hand and leave it unmanaged.** Set the dashboard endpoint's event list to `rake stripe:enabled_events` output. Five minutes, no cutover, but the endpoint stays absent from code — the situation this module exists to end.

Either way, run `rake stripe:webhook_status` afterwards. It is read-only and reports both the endpoint's `status` and any drift against the canonical list.

## Endpoint auto-disable

Stripe disables an endpoint that fails persistently. **There is no Stripe event type for this** — checked against the 236 types in the API reference and the 266 in Stripe's OpenAPI `enabled_events` enum; none match `webhook_endpoint.*` or any disable-related name. Stripe cannot webhook you to tell you your webhook is broken.

Worse, the email that used to be documented is no longer documented at all: the "Disable behavior" section ("Stripe attempts to notify you of a misconfigured endpoint by email…") was present on `docs.stripe.com/webhooks` through 2024-08-07 and removed by 2024-09-09. The behaviour is widely believed to persist, but it is no longer a contract.

**So detection must be pull-based.** `GET /v1/webhook_endpoints` returns a `status` field of `enabled` or `disabled`, which this module exports as `webhook_endpoint_status` and `rake stripe:webhook_status` polls. Schedule that task; a silently disabled endpoint is otherwise indistinguishable from "no events are happening", and that ambiguity is the actual risk — not silent loss, which Stripe's 3-day retry and 30-day event retention already cover.
