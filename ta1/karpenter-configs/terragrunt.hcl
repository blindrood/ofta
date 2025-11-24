# This is a Terragrunt module for Karpenter configurations (NodePool, EC2NodeClass)
terraform {
  source = "."
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "karpenter" {
  config_path = "../karpenter"
}

dependency "eks" {
  config_path = "../eks"
}

inputs = {
  cluster_name        = dependency.eks.outputs.cluster_id
  cluster_endpoint    = dependency.eks.outputs.cluster_endpoint
  cluster_auth_base64 = dependency.eks.outputs.cluster_auth_base64
  tags                = include.root.local.tags
}
