resource "alicloud_oss_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = false
  tags          = var.tags

  server_side_encryption_rule {
    sse_algorithm     = var.server_side_encryption_algorithm
    kms_master_key_id = var.kms_key_id
  }

  versioning {
    status = var.bucket_versioning ? "Enabled" : "Suspended"
  }

  lifecycle {
    ignore_changes = [acl, policy]

    precondition {
      condition     = var.server_side_encryption_algorithm != "KMS" || var.kms_key_id != null
      error_message = "Provide KMS key when using KMS encryption"
    }

    precondition {
      condition     = var.server_side_encryption_algorithm == "KMS" || var.kms_key_id == null
      error_message = "Provide KMS key only when using KMS encryption"
    }
  }
}

resource "alicloud_oss_bucket_acl" "this" {
  bucket = alicloud_oss_bucket.this.bucket
  acl    = "private"
}

resource "alicloud_oss_bucket_https_config" "this" {
  bucket       = alicloud_oss_bucket.this.bucket
  enable       = true
  tls_versions = var.tls_versions
}

resource "alicloud_oss_bucket_policy" "this" {
  bucket = alicloud_oss_bucket.this.bucket
  policy = jsonencode({
    Version = "1"
    Statement = [{
      Effect    = "Deny"
      Principal = ["*"]
      Action    = ["oss:*"]
      Resource  = ["acs:oss:*:*:${alicloud_oss_bucket.this.bucket}", "acs:oss:*:*:${alicloud_oss_bucket.this.bucket}/*"]
      Condition = {
        Bool = { "acs:SecureTransport" = ["false"] }
      }
    }]
  })
}

resource "alicloud_oss_access_point" "this" {
  for_each = var.vpc_access_points

  bucket            = alicloud_oss_bucket.this.bucket
  access_point_name = each.key
  network_origin    = "vpc"

  vpc_configuration {
    vpc_id = each.value.vpc_id
  }

  public_access_block_configuration {
    block_public_access = true
  }

  depends_on = [alicloud_oss_bucket_acl.this, alicloud_oss_bucket_https_config.this, alicloud_oss_bucket_policy.this]
}