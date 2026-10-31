variable "bucket_name" {
  description = "OSS bucket name, must be globally unique, lower case letters and numbers and hyphens, up to 63 characters"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name invalid"
  }
}

variable "server_side_encryption_algorithm" {
  description = "SSE algorithm"
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "KMS"], var.server_side_encryption_algorithm)
    error_message = "Must be AES256 or KMS"
  }
}

variable "kms_key_id" {
  description = "KMS key for KMS encryption"
  type        = string
  default     = null
}

variable "tls_versions" {
  description = "TLS versions, required to use modern TLS"
  type        = set(string)
  default     = ["TLSv1.2", "TLSv1.3"]

  validation {
    condition     = length(var.tls_versions) > 0 && alltrue([for version in var.tls_versions : contains(["TLSv1.2", "TLSv1.3"], version)])
    error_message = "Must be TLSv1.2 or TLSv1.3 or both"
  }
}

variable "logging_target_bucket" {
    description = "Bucket to store access logs"
    type        = string
    default     = null
}

variable "logging_target_prefix" {
    description = "Name prefix for access logs"
    type        = string
    default     = null
}

variable "bucket_versioning" {
    description = "Weather to enable versioning or not"
    type        = bool
    default     = false
}

variable "vpc_access_points" {
  description = "Provide OSS access point names to create VPC access points"
  type = map(object({
    vpc_id = string
  }))
  default = {}

  validation {
    condition     = alltrue([for name, point in var.vpc_access_points : can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", name)) && can(regex("^vpc-[a-zA-Z0-9]+$", point.vpc_id))])
    error_message = "Access point names must be 3-63 characters, VPC IDs must start with vpc-"
  }
}

variable "tags" {
  description = "Bucket tags"
  type        = map(string)
  default     = {}

  validation {
    condition     = length(var.tags) <= 20
    error_message = "OSS supports max 20 bucket tags"
  }
}

