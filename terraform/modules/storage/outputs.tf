output "bucket_id" {
  description = "Identifier of the generated bucket metadata resource."
  value       = local_file.bucket_metadata.id
}

output "bucket_path" {
  description = "Path to the generated bucket metadata file."
  value       = module.storage.bucket_path
