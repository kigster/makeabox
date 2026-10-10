variable "project_id" { type = string }
variable "region" { type = string }
variable "environment" { type = string }
variable "rails_master_key_secret_name" {
  type        = string
  description = "The name of the Secret Manager secret containing the Rails master key"
}

variable "rails_env" {
  type        = string
  default     = "production"
  description = "RAILS_ENV for both Cloud Run services (e.g. production, staging)"
}

variable "db_name" {
  type        = string
  default     = "makeabox_production"
  description = "Cloud SQL database name. Default preserves the existing prod database; changing it on a live environment forces the database to be replaced."
}

variable "deletion_protection" {
  type        = bool
  default     = true
  description = "Protect the Cloud SQL instance from terraform destroy. Override to false for disposable environments."
}

variable "domain" {
  type        = string
  default     = ""
  description = "Custom domain to map to the web service (empty = no mapping). Must be verified via Search Console / `gcloud domains verify` first."
}
