terraform {
  required_version = ">= 1.5.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

# No credentials required: the local provider only writes files on disk,
# which is enough to model "infrastructure" for this local-only exercise.
provider "local" {}

# NOTE: this resource duplicates what terraform/modules/storage already
# provides. The intended design is to call module "storage" here instead
# of hand-defining the bucket metadata file again.
resource "local_file" "cloudnotes_bucket" {
  filename = "${path.module}/.generated/${var.environment}-bucket.json"
  content = jsonencode({
    bucket_name = var.bucket_name
    environment = var.environment
    labels      = var.labels
  })
}

# Release manifest for the build the student is shipping.
resource "local_file" "release_manifest" {
  filename = "${path.module}/.generated/${var.environment}-release-manifest.json"
  content = jsonencode({
    # This should reference var.bucket_name (declared in variables.tf).
    bucket      = var.bucket_name
    environment = var.environment
  })
}
