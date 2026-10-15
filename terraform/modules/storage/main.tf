module "storage"{
  source = "./module/storage"
  bucket_name = var.bucket_name
  environment = var.environment
  labels      = var.labels
}