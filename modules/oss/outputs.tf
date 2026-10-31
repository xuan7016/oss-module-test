output "bucket_name" {
  description = "Provisioned OSS bucket name."
  value       = alicloud_oss_bucket.this.bucket
}

output "intranet_endpoint" {
  description = "Bucket intranet endpoint; not an access point endpoint."
  value       = alicloud_oss_bucket.this.intranet_endpoint
}

output "access_point_ids" {
  description = "Access point IDs keyed by name."
  value       = { for name, point in alicloud_oss_access_point.this : name => point.id }
}