#!/usr/bin/env bash
# shellcheck disable=SC2015,SC1091

[[ -d "${HOME}/.bashmatic" ]] || bash -c "$(curl -fsSL https://bashmatic.re1.re); bashmatic-install -q"
source "${HOME}/.bashmatic/init" >/dev/null

function have_command() {
  local cmd="$1"
  command -v "${cmd}" >/dev/null
}

h3bg "Ensuring IaC dependencies are installed..."

have_command gcloud && {
  info "Google Cloud CLI is installed, version $(gcloud --version | tr '\n' ' ')"
} || {
  h2 "Installing gcloud CLI..."
  run.set-next show-output-on
  run "curl https://sdk.cloud.google.com | bash"
}

have_command terraform && {
  info "Terraform already installed, version $(terraform --version | tr '\n' '→ ')"
} || {
  h2 "Installing Terraform..."
  run "brew tap hashicorp/tap"
  run "brew install hashicorp/tap/terraform"
}

have_command terragrunt && {
  info "TerraGrunt already installed, version $(terragrunt --version)"
} || {
  h2 "Installing Terragrunt..."
  run "curl -sSfL --proto '=https' --tlsv1.2 https://terragrunt.com/install | bash"
}

function apply-prod() {
  h1 "About to run terragrunt init in iac/envs/prod"
  run.ui.ask "Run terragrunt init?"

  cd iac/envs/prod || exit 1
  run "terragrunt init"
  run "terragrunt apply $*"
}

apply-prod "$@"


