# This is a Terragrunt module for EKS cluster infrastructure.
terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-eks/?ref=v21.9.0"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "vpc" {
  config_path = "../vpc"
}

inputs = {
  name               = "primary-cluster"
  kubernetes_version = "1.33"

  vpc_id                   = dependency.vpc.outputs.vpc_id
  subnet_ids               = dependency.vpc.outputs.private_subnets
  control_plane_subnet_ids = dependency.vpc.outputs.intra_subnets

  endpoint_private_access                  = true
  endpoint_public_access                   = true
  enable_cluster_creator_admin_permissions = true

  tags = include.root.local.tags

  addons = {
    coredns = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
  }

  # Create a minimal bootstrap node group for cluster initialization
  # Karpenter will handle the actual workload nodes
  eks_managed_node_groups = {
    bootstrap = {
      min_size     = 1
      max_size     = 2
      desired_size = 1

      instance_types = ["t3.small"] # Using smaller instances for bootstrap only

      # Use private subnets for the bootstrap nodes
      subnet_ids = dependency.vpc.outputs.private_subnets

      # Additional tags for the node group
      tags = include.root.local.tags
    }
  }

  # Configure the cluster identity provider
  authentication_mode = "API_AND_CONFIG_MAP"
}
