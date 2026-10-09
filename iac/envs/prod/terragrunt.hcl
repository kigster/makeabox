include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../modules/gcp_stack"
}

inputs = {
  project_id  = "qualifiedat-production"
  region      = "us-central1"
  environment = "prod"
  rails_env   = "production"

  # Pass the name of the secret as it exists in GCP Secret Manager
  rails_master_key_secret_name = "rails-master-key"

  # Custom domain mapped to the web service (must be pre-verified with Google)
  domain = "qualified.at"
}
