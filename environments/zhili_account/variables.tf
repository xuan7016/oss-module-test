variable "region" {
  description = "Alibaba Cloud region shared by OSS, VPCs and the KMS key."
  type        = string
}

variable "bucket_name" {
  description = "Globally unique bucket name."
  type        = string
}

variable "encryption_algorithm" {
  description = "AES256 or KMS."
  type        = string
  default     = "AES256"
}

variable "kms_key_id" {
  description = "Existing KMS key ID, required when using KMS."
  type        = string
  default     = null
}

variable "tls_versions" {
  description = "Allowed modern TLS versions."
  type        = set(string)
  default     = ["TLSv1.2", "TLSv1.3"]
}

variable "access_points" {
  description = "Map of access point names to existing VPC IDs."
  type        = map(object({ vpc_id = string }))
  default     = {}
}