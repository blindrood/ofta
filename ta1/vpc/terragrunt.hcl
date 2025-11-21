# This is a Terragrunt module for VPC infrastructure.
terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc?ref=v6.5.1"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  name = "eks-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway   = true
  enable_vpn_gateway   = false
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Additional tags for all resources
  tags = include.root.local.tags

  # Tags specifically for the VPC
  vpc_tags = merge(include.root.local.tags, {
    Name                                    = "eks-vpc"
    "kubernetes.io/cluster/primary-cluster" = "shared"
  })

  # Tags for private subnets - needed for EKS node auto-discovery
  private_subnet_tags = merge(include.root.local.tags, {
    "kubernetes.io/role/internal-elb"       = "1"
    "kubernetes.io/cluster/primary-cluster" = "shared"
  })

  # Tags for public subnets - needed for EKS node auto-discovery
  public_subnet_tags = merge(include.root.local.tags, {
    "kubernetes.io/role/elb"                = "1"
    "kubernetes.io/cluster/primary-cluster" = "shared"
  })

  # Tags for route tables to help with EKS load balancer discovery
  public_route_table_tags = merge(include.root.local.tags, {
    "kubernetes.io/role/elb" = "1"
  })
  private_route_table_tags = merge(include.root.local.tags, {
    "kubernetes.io/role/internal-elb" = "1"
  })
}
