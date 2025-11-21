inputs {}

locals {
    tf_aws_backend_bucket = "tbd"
    tf_aws_backend_table = "tbd"
    tf_aws_backend_region = "eu-central-1"
    project_vars = read_terragrunt_config(find_in_parent_folders("project.tfvars", "_.tfvars"), { locals = {
        account_id      = "",
        region          = "",
    })
    # Extract the variables we need for easy access
    account_id = local.project_vars.locals.account_id
    region     = local.project_vars.locals.region
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "${local.tf_aws_backend_bucket}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "${local.tf_aws_backend_region}"
    encrypt        = true
    dynamodb_table = "${local.tf_aws_backend_table}"
  }
}

terraform_version_constraint  = ">= 1.13, < 2.0"
terragrunt_version_constraint = ">= 0.93, <1.0"


include {
  path = find_in_parent_folders()
}

generate "providers" {
  path      = "providers.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
provider "aws" {
  region = ${local.region}
}
EOF
}

generate "versions" {
  path      = "versions.tf"
  if_exists = "skip"
  contents  = <<EOF
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.22"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.1"
    }
  }
}
EOF
}
