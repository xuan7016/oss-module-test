## OSS Module
This repo implements the OSS module as requested
- Terraform tests defined in `modules/oss/tests`, it will be ran through GHA. I also did a manual run of terraform tests, see https://github.com/xuan7016/oss-module-test/actions/runs/41182713678
- Ability to define VPC access points through a variable `vpc_access_points`
- Encryption and TLS requirements are enforced by terraform variable checks as well as OPA rules

    - TLS requirements are defaulted to TLSv1.2 and TLSv1.3, and variable checks will require you to choose one of them or all of them
    - SSE is default to enabled
    - ACL is default to private to prevent open bucket
    - OPA also checks if SSE is set as "AES256" or "KMS"

- Resources are provisioned to my own account through Github Actions. The terraform code is located in `environments/zhili_account`. The terraform state file is setup as a remote state file located in a bucket in my account. See below for some screenshots. 
You can also see in the action history for the PR planning and application runs.

    - Plan triggered by the PR: https://github.com/xuan7016/oss-module-test/actions/runs/41184758648
    - Application triggered when PR is merged: https://github.com/xuan7016/oss-module-test/actions/runs/41185268339

> [!NOTE]
> Lifecycle policies are not included in variables and validations since this was not requested.

### Actions
The pipelines are setup through Github Actions. They are located in the `.github/workflows` directory. There are 3 pipelines configured.

`ci.yml` runs when there are new PR created with changes to the `modules/oss` directory. It initalizes terraform and run terraform tests on the PR.

`plan.yml` is triggered when there is a new PR created with changed to the `environments` directory. It installs terraform and OPA. Authenticates with Aliyun through OIDC, generates the terraform plan and runs OPA evaluations on the plan. 

`apply.yml` is only triggered when a PR is merged to `main`, since during the PR phase all checks should have been done, this pipeline applies the terraform directly. 

### Screenshots
Server side encryption:
![SSE](/readme_images/sse.png?raw=true "SSE Enabled")

TLS Version:
![TLS](/readme_images/tls.png?raw=true "TLS Versioning")

Bucket Policy:
![Policy](/readme_images/deny-non-secure.png?raw=true "Policy")

VPC Access Point:
![VPC Access Point](/readme_images/vpc-access-point.png?raw=true "VPC Access Point")

No Public Access:
![Private](/readme_images/block-public.png?raw=true "Private")