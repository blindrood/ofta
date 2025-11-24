# EKS with Karpenter Infrastructure

This repository contains the Terraform and Terragrunt code to deploy a complete EKS cluster with Karpenter for advanced autoscaling capabilities, including support for Graviton (ARM64) and Spot instances.

## Architecture Overview

This setup includes:

- A dedicated VPC with public and private subnets
- An EKS cluster with latest Kubernetes version
- Karpenter for advanced autoscaling with support for:
  - x86 (amd64) and ARM64 (Graviton) instances
  - Spot and On-Demand instances
  - Multiple instance types for optimal cost/performance

## Prerequisites

1. AWS CLI configured with appropriate permissions
2. Terraform >= 1.5
3. Terragrunt >= 0.50
4. kubectl for interacting with the cluster after deployment

## Deployment Steps

### 1. Update Configuration

First, update the `project.tfvars` file with your specific values:

```hcl
account_id = "YOUR_ACCOUNT_ID"
region     = "eu-central-1"  # Or your preferred region
```

Also update the `root.hcl` file with your S3 backend configuration:

```hcl
locals {
  tf_aws_backend_bucket = "your-terraform-state-bucket"
  tf_aws_backend_table  = "your-dynamodb-lock-table"
  tf_aws_backend_region = "eu-central-1"
  # ... rest of the file
}
```

### 2. Deploy Infrastructure

Deploy the infrastructure in the following order:

1. **VPC**:

   ```bash
   cd vpc
   terragrunt run -- init
   terragrunt run -- plan
   terragrunt run -- apply
   ```

2. **EKS**:

   ```bash
   cd ../eks
   terragrunt run -- init
   terragrunt run -- plan
   terragrunt run -- apply
   ```

3. **Karpenter**:

   ```bash
   cd ../karpenter
   terragrunt run -- init
   terragrunt run -- plan
   terragrunt run -- apply
   ```

4. **Karpenter Configurations**:

   ```bash
   cd ../karpenter-configs
   terragrunt run -- init
   terragrunt run -- plan
   terragrunt run -- apply
   ```

Alternatively, you can use terragrunt's dependency management to deploy everything at once from the root directory:

```bash
terragrunt run --all -- init
terragrunt run --all -- plan
terragrunt run --all -- apply
```

### 3. Configure kubectl

After deployment, configure kubectl to connect to your cluster:

```bash
aws eks --region <your-region> update-kubeconfig --name primary-cluster
```

## Using Karpenter

### Deploying Workloads on Specific Architectures

Karpenter allows you to schedule workloads on specific instance types using node selectors and tolerations.

#### Example: Deploy on ARM64 (Graviton) instances

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: arm64-workload
spec:
  replicas: 2
  selector:
    matchLabels:
      app: arm64-workload
  template:
    metadata:
      labels:
        app: arm64-workload
    spec:
      # Request ARM64 architecture
      nodeSelector:
        kubernetes.io/arch: arm64
      containers:
      - name: app
        image: nginx
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
```

#### Example: Deploy on x86 instances

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: x86-workload
spec:
  replicas: 2
  selector:
    matchLabels:
      app: x86-workload
  template:
    metadata:
      labels:
        app: x86-workload
    spec:
      # Request x86_64 architecture
      nodeSelector:
        kubernetes.io/arch: amd64
      containers:
      - name: app
        image: nginx
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
```

#### Example: Deploy on Spot instances

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: spot-workload
spec:
  replicas: 3
  selector:
    matchLabels:
      app: spot-workload
  template:
    metadata:
      labels:
        app: spot-workload
    spec:
      # Request Spot instances
      nodeSelector:
        karpenter.sh/capacity-type: spot
      containers:
      - name: app
        image: nginx
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
```

### Checking Karpenter Status

To check if Karpenter is running:

```bash
kubectl get pods -n karpenter
```

To view Karpenter logs:

```bash
kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter -c controller
```

To see Karpenter's provisioned nodes:

```bash
kubectl get nodes
kubectl get nodepools
kubectl get ec2nodeclasses
```

## Architecture Details

### VPC Configuration

- 3 Availability Zones for high availability
- Public subnets for load balancers and internet-facing services
- Private subnets for nodes and internal services
- NAT Gateways for internet access from private subnets

### EKS Configuration

- Latest Kubernetes version
- Private API server endpoint
- Control plane logging enabled
- Bootstrap node group for cluster initialization
- IRSA (IAM Roles for Service Accounts) enabled

### Karpenter Configuration

- Default NodePool supporting both x86 and ARM64
- Separate NodePools for architecture-specific workloads
- Spot instance support for cost optimization
- EC2NodeClass with AL2023 AMI family
- Interruption handling for Spot instances

## Cleanup

To destroy the infrastructure:

```bash
cd karpenter-configs
terragrunt run -- destroy

cd ../karpenter
terragrunt run -- destroy

cd ../eks
terragrunt run -- destroy

cd ../vpc
terragrunt run -- destroy
```

Or use the run-all command from the root:

```bash
terragrunt run --all -- destroy
```

## Important Notes

1. The bootstrap node group is needed for cluster initialization. Karpenter will handle the actual workload nodes.

2. Spot instances offer significant cost savings but can be interrupted. Ensure your applications are designed to handle this.

3. Graviton (ARM64) instances provide better price/performance for many workloads. Ensure your container images support ARM64 architecture.

4. Always test your applications on different instance types before deploying to production.

5. Monitor your cluster resources and adjust Karpenter NodePool limits as needed.
