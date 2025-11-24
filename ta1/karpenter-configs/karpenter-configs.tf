variable "tags" {
  description = "Map of tags to apply to resources"
  type        = map(string)
  default     = {}
}

provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_auth_base64)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = ["eks", "get-token", "--cluster-name", var.cluster_name]
  }
}

resource "kubernetes_manifest" "default_nodepool" {
  manifest = {
    apiVersion = "karpenter.sh/v1beta1"
    kind       = "NodePool"
    metadata = {
      name = "default"
    }
    spec = {
      template = {
        spec = {
          requirements = [
            {
              key      = "karpenter.k8s.aws/instance-category"
              operator = "In"
              values   = ["c", "m", "r", "t"]
            },
            {
              key      = "karpenter.k8s.aws/instance-generation"
              operator = "Gt"
              values   = ["2"]
            },
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = ["spot", "on-demand"]
            },
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["amd64", "arm64"]
            }
          ]
          nodeClassRef = {
            name = "default"
          }
          expireAfter = "720h"
          taints = []
        }
      }
      limits = {
        resources = {
          cpu    = "1000"
          memory = "1000Gi"
        }
      }
      disruption = {
        consolidationPolicy = "WhenUnderutilized"
        expireAfter = "720h"
      }
    }
  }
}

resource "kubernetes_manifest" "default_ec2nodeclass" {
  manifest = {
    apiVersion = "karpenter.k8s.aws/v1beta1"
    kind       = "EC2NodeClass"
    metadata = {
      name = "default"
    }
    spec = {
      amiFamily = "AL2023"

      subnetSelectorTerms = [
        {
          tags = {
            "kubernetes.io/cluster/${var.cluster_name}" = "shared"
          }
        }
      ]

      securityGroupSelectorTerms = [
        {
          tags = {
            "kubernetes.io/cluster/${var.cluster_name}" = "shared"
          }
        }
      ]

      tags = {
        Karpenter   = "true"
        Name        = "karpenter-node-${var.cluster_name}"
        Environment = var.tags["Environment"]
        Project     = var.tags["Project"]
        ManagedBy   = var.tags["ManagedBy"]
      }
    }
  }
}

resource "kubernetes_manifest" "arm64_nodepool" {
  manifest = {
    apiVersion = "karpenter.sh/v1beta1"
    kind       = "NodePool"
    metadata = {
      name = "arm64-pool"
    }
    spec = {
      template = {
        spec = {
          requirements = [
            {
              key      = "karpenter.k8s.aws/instance-category"
              operator = "In"
              values   = ["c", "m", "r"]
            },
            {
              key      = "karpenter.k8s.aws/instance-generation"
              operator = "Gt"
              values   = ["2"]
            },
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = ["spot", "on-demand"]
            },
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["arm64"]
            }
          ]
          nodeClassRef = {
            name = "default"
          }
          expireAfter = "720h"
        }
      }
      limits = {
        resources = {
          cpu    = "500"
          memory = "500Gi"
        }
      }
      disruption = {
        consolidationPolicy = "WhenUnderutilized"
        expireAfter = "720h"
      }
    }
  }
}

resource "kubernetes_manifest" "x86_nodepool" {
  manifest = {
    apiVersion = "karpenter.sh/v1beta1"
    kind       = "NodePool"
    metadata = {
      name = "x86-pool"
    }
    spec = {
      template = {
        spec = {
          requirements = [
            {
              key      = "karpenter.k8s.aws/instance-category"
              operator = "In"
              values   = ["c", "m", "r"]
            },
            {
              key      = "karpenter.k8s.aws/instance-generation"
              operator = "Gt"
              values   = ["2"]
            },
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = ["spot", "on-demand"]
            },
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["amd64"]
            }
          ]
          nodeClassRef = {
            name = "default"
          }
          expireAfter = "720h"
        }
      }
      limits = {
        resources = {
          cpu    = "500"
          memory = "500Gi"
        }
      }
      disruption = {
        consolidationPolicy = "WhenUnderutilized"
        expireAfter = "720h"
      }
    }
  }
}
