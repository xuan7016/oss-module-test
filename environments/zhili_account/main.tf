terraform {
  required_version = ">= 1.7.0, < 2.0.0"

  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = ">= 1.240.0, < 2.0.0"
    }
  }

  backend "oss" {}
}

provider "alicloud" {
  region = var.region
}

module "oss" {
  source = "../../modules/oss"

  bucket_name                      = var.bucket_name
  server_side_encryption_algorithm = var.encryption_algorithm
  kms_key_id                       = var.kms_key_id
  tls_versions                     = var.tls_versions
  vpc_access_points                = var.access_points
  tags                             = { ManagedBy = "Terraform", Environment = "production" }
}

output "bucket_name" {
  value = module.oss.bucket_name
}

output "access_point_ids" {
  value = module.oss.access_point_ids
}