bucket              = "test-terraform-state-1456485998503207"
region              = "cn-shanghai"
prefix              = "terraform/oss/"
key                 = "terraform.tfstate"
encrypt             = true
acl                 = "private"
tablestore_endpoint = "https://tf-statelock.cn-shanghai.ots.aliyuncs.com"
tablestore_table    = "terraform_locks"