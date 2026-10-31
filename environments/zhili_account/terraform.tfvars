region               = "cn-shanghai"
bucket_name          = "zhili-module-test-bucket"
encryption_algorithm = "AES256"
tls_versions         = ["TLSv1.2", "TLSv1.3"]
access_points = {
  app-private = { vpc_id = "vpc-uf6d5muatc0ct1zvkz07c" }
}