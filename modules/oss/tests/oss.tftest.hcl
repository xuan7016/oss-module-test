mock_provider "alicloud" {}

variables {
  bucket_name = "oss-test"
}

run "security_configurations" {
  command = plan

  assert {
    condition     = alicloud_oss_bucket_acl.this.acl == "private"
    error_message = "Bucket ACL must be private"
  }

  assert {
    condition     = one(alicloud_oss_bucket.this.server_side_encryption_rule).sse_algorithm == var.server_side_encryption_algorithm
    error_message = "Must have SSE set"
  }

  assert {
    condition     = alicloud_oss_bucket_https_config.this.enable && alicloud_oss_bucket_https_config.this.tls_versions == toset(["TLSv1.2", "TLSv1.3"])
    error_message = "Must be TLSv1.2 or TLSv1.3"
  }

  assert {
    condition     = jsondecode(alicloud_oss_bucket_policy.this.policy).Statement[0].Condition.Bool["acs:SecureTransport"] == ["false"]
    error_message = "Must only use HTTPS"
  }

  assert {
    condition     = !alicloud_oss_bucket.this.force_destroy
    error_message = "Force destroy must not be set"
  }

  assert {
    condition     = one(alicloud_oss_bucket.this.versioning).status == (var.bucket_versioning ? "Enabled" : "Suspended")
    error_message = "Versioning must match the configured setting"
  }
}

run "kms_encryption" {
  command = plan

  variables {
    server_side_encryption_algorithm = "KMS"
    kms_key_id                       = "some-existing-kms-key"
    tls_versions                     = ["TLSv1.3"]
  }

  assert {
    condition     = one(alicloud_oss_bucket.this.server_side_encryption_rule).sse_algorithm == "KMS" && one(alicloud_oss_bucket.this.server_side_encryption_rule).kms_master_key_id == var.kms_key_id
    error_message = "KMS and the key must be set"
  }
}

run "vpc_access_points" {
  command = plan

  variables {
    vpc_access_points = {
      vpc-aaaaaaa-access-point = { vpc_id = "vpc-aaaaaaa" }
      vpc-sssssss-access-point = { vpc_id = "vpc-sssssss" }
    }
  }

 assert {
    condition = length(alicloud_oss_access_point.this) == 2
    error_message = "Should created 2 access points"
 }

  assert {
    condition     = alltrue([for point in alicloud_oss_access_point.this : point.network_origin == "vpc" && one(point.public_access_block_configuration).block_public_access])
    error_message = "Every access point must be VPC-only and block public access"
  }
}

run "test_legacy_tls" {
  command = plan
  variables {
    tls_versions = ["TLSv1.0"]
  }
  expect_failures = [var.tls_versions]
}

run "test_no_tls" {
  command = plan
  variables {
    tls_versions = []
  }
  expect_failures = [var.tls_versions]
}

run "test_missing_kms_key" {
  command = plan
  variables {
    server_side_encryption_algorithm = "KMS"
    kms_key_id                       = null
  }
  expect_failures = [alicloud_oss_bucket.this]
}

run "test_invalid_bucket_name" {
  command = plan
  variables {
    bucket_name = "_NAME"
  }
  expect_failures = [var.bucket_name]
}

run "test_max_bucket_name_length" {
  command = plan
  variables {
    bucket_name = format("%064d", 0)
  }
  expect_failures = [var.bucket_name]
}

run "reject_invalid_vpc" {
  command = plan
  variables {
    vpc_access_points = { test = { vpc_id = "" } }
  }
  expect_failures = [var.vpc_access_points]
}