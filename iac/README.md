# MakeABox.io - GCP Infrastructure as Code

This repository contains the Terraform and Terragrunt configuration to deploy the MakeABox.io Rails application to Google Cloud Platform (GCP).

## Architecture Overview

- **Web Tier:** Google Cloud Run (Puma server, scales to zero or based on traffic).
- **Worker Tier:** Google Cloud Run (Sidekiq worker, minimum 1 instance, CPU always allocated).
- **Database:** Google Cloud SQL (PostgreSQL 15).
- **Cache/Queue:** Google Cloud Memorystore (Redis).
- **Networking:** Direct VPC Egress connects Cloud Run securely to Redis and Cloud SQL.

## Prerequisites

3. [Google Cloud SDK (gcloud)](https://cloud.google.com/sdk/docs/install) installed and authenticated.
1. A GCP Project created with billing enabled.
1. A Docker image of the Rails app pushed to Google Artifact Registry (or GCR).

## Directory Structure

```
iac/
├── README.md
├── terragrunt.hcl
├── envs/
│   └── prod/
│       └── terragrunt.hcl
└── modules/
    └── gcp_stack/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```
