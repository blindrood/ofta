variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "Endpoint of the EKS cluster"
  type        = string
}

variable "cluster_auth_base64" {
  description = "Base64 encoded CA of the EKS cluster"
  type        = string
}
