variable "environment" {
  description = "Deployment environment name (dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "storage_bucket_name" {
  description = "Logical name for the CloudNotes storage bucket (simulated locally)."
  type        = string
  default     = "cloudnotes-artifacts"
}

variable "labels" {
  description = "Common labels/tags applied to generated resources."
  type        = map(string)
  default = {
    project = "cloudnotes"
    owner   = "platform-team"
  }
}
