# Staging is not provisioned yet. When it is, mirror envs/prod/terragrunt.hcl:
#
# include "root" {
#   path = find_in_parent_folders("root.hcl")
# }
#
# terraform {
#   source = "../../modules/gcp_stack"
# }
#
# inputs = {
#   project_id  = "qualifiedat-staging"
#   region      = "us-central1"
#   environment = "staging"
#   rails_env   = "staging"
#   db_name     = "qualified_staging"
#   deletion_protection = false
#   rails_master_key_secret_name = "rails-master-key"
# }
