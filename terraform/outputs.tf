output "storage" {
  description = "Path to the generated storage module file."
  value       = local_file.storage.filename
}

output "release_manifest_path" {
  description = "Path to the generated release manifest file."
  value       = local_file.release_manifest.filename
}
