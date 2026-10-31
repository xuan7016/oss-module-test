package oss

import rego.v1

resources := [resource |
	some path, resource
	walk(input.planned_values.root_module, [path, resource])
	is_object(resource)
	object.get(resource, "mode", "") == "managed"
	startswith(object.get(resource, "type", ""), "alicloud_oss_")
]

buckets := [resource | some resource in resources; resource.type == "alicloud_oss_bucket"]

deny contains "Plan must contain at least one OSS bucket with planned values" if {
	count(buckets) == 0
}

encrypted(bucket) if {
	some rule in bucket.values.server_side_encryption_rule
	rule.sse_algorithm == "AES256"
}

encrypted(bucket) if {
	some rule in bucket.values.server_side_encryption_rule
	rule.sse_algorithm == "KMS"
	is_string(rule.kms_master_key_id)
	trim_space(rule.kms_master_key_id) != ""
}

private_acl(bucket) if {
	some resource in resources
	resource.type == "alicloud_oss_bucket_acl"
	resource.values.bucket == bucket.values.bucket
	resource.values.acl == "private"
}

modern_tls(bucket) if {
	some resource in resources
	resource.type == "alicloud_oss_bucket_https_config"
	resource.values.bucket == bucket.values.bucket
	resource.values.enable == true
	versions := resource.values.tls_versions
	is_array(versions)
	count(versions) > 0
	every version in versions {
		version in {"TLSv1.2", "TLSv1.3"}
	}
}

https_only(bucket) if {
	some resource in resources
	resource.type == "alicloud_oss_bucket_policy"
	resource.values.bucket == bucket.values.bucket
	json.is_valid(resource.values.policy)
	document := json.unmarshal(resource.values.policy)
	document.Version == "1"
	some statement in document.Statement
	statement.Effect == "Deny"
	"*" in statement.Principal
	"oss:*" in statement.Action
	sprintf("acs:oss:*:*:%s", [bucket.values.bucket]) in statement.Resource
	sprintf("acs:oss:*:*:%s/*", [bucket.values.bucket]) in statement.Resource
	statement.Condition == {"Bool": {"acs:SecureTransport": ["false"]}}
}

deny contains sprintf("%s: require AES256 or KMS", [bucket.address]) if {
	some bucket in buckets
	not encrypted(bucket)
}

deny contains sprintf("%s: require a private bucket ACL", [bucket.address]) if {
	some bucket in buckets
	not private_acl(bucket)
}

deny contains sprintf("%s: require TLSv1.2 orTLSv1.3", [bucket.address]) if {
	some bucket in buckets
	not modern_tls(bucket)
}

deny contains sprintf("%s: require deny of plain HTTP", [bucket.address]) if {
	some bucket in buckets
	not https_only(bucket)
}

public_principal(principals) if {
	"*" in principals
}

public_principal(principals) if {
	is_array(principals)
	count(principals) == 0
}

deny contains sprintf("%s: public Allow statements are forbidden", [resource.address]) if {
	some resource in resources
	resource.type == "alicloud_oss_bucket_policy"
	json.is_valid(resource.values.policy)
	document := json.unmarshal(resource.values.policy)
	some statement in document.Statement
	statement.Effect == "Allow"
	public_principal(statement.Principal)
}

vpc_only(resource) if {
	resource.values.network_origin == "vpc"
	some configuration in resource.values.vpc_configuration
	regex.match("^vpc-[a-zA-Z0-9]+$", configuration.vpc_id)
	some block in resource.values.public_access_block_configuration
	block.block_public_access == true
}

deny contains sprintf("%s: access points must be VPC-only with public access blocked", [resource.address]) if {
	some resource in resources
	resource.type == "alicloud_oss_access_point"
	not vpc_only(resource)
}

deny contains sprintf("%s: bucket deletion or replacement requires a separate reviewed policy exception", [change.address]) if {
	some change in input.resource_changes
	change.type == "alicloud_oss_bucket"
	"delete" in change.change.actions
}
