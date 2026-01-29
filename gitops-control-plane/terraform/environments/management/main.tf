# Management Cluster Terraform Configuration
# This creates the hub cluster that runs Crossplane and Flux

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.11"
    }
  }

  backend "s3" {
    bucket         = "gitops-terraform-state"
    key            = "management-cluster/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "gitops-control-plane"
      Environment = "management"
      ManagedBy   = "terraform"
    }
  }
}

# EKS Cluster Module
module "eks" {
  source = "../../modules/eks"

  cluster_name = "management"
  environment  = "production"  # Management cluster runs as production
  region       = var.region
  vpc_cidr     = var.vpc_cidr

  kubernetes_version     = var.kubernetes_version
  enable_public_endpoint = true  # Management cluster needs external access

  # System node group for platform components
  system_node_instance_types = ["m6i.xlarge"]
  system_node_min_size       = 3
  system_node_max_size       = 6
  system_node_desired_size   = 3

  # Application node group for Crossplane workloads
  app_node_instance_types = ["m6i.2xlarge"]
  app_node_min_size       = 2
  app_node_max_size       = 10
  app_node_desired_size   = 3

  # Route53 zones for External DNS
  route53_zone_arns = var.route53_zone_arns

  # Enable Crossplane IRSA
  enable_crossplane = true

  tags = var.tags
}

# Kubernetes provider configuration
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_name,
      "--region",
      var.region
    ]
  }
}

# Helm provider configuration
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        module.eks.cluster_name,
        "--region",
        var.region
      ]
    }
  }
}

# Install Flux
resource "helm_release" "flux" {
  name             = "flux"
  repository       = "https://fluxcd-community.github.io/helm-charts"
  chart            = "flux2"
  version          = var.flux_version
  namespace        = "flux-system"
  create_namespace = true

  set {
    name  = "imageReflectorController.create"
    value = "true"
  }

  set {
    name  = "imageAutomationController.create"
    value = "true"
  }

  depends_on = [module.eks]
}

# Install Crossplane
resource "helm_release" "crossplane" {
  name             = "crossplane"
  repository       = "https://charts.crossplane.io/stable"
  chart            = "crossplane"
  version          = var.crossplane_version
  namespace        = "crossplane-system"
  create_namespace = true

  set {
    name  = "args"
    value = "{--enable-composition-functions,--enable-composition-webhook-schema-validation}"
  }

  depends_on = [module.eks]
}

# Create namespace for fleet cluster management
resource "kubernetes_namespace" "fleet_clusters" {
  metadata {
    name = "fleet-clusters"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "purpose"                      = "cluster-management"
    }
  }

  depends_on = [module.eks]
}

# Store cluster credentials in AWS Secrets Manager
resource "aws_secretsmanager_secret" "kubeconfig" {
  name        = "gitops-control-plane/management-cluster/kubeconfig"
  description = "Kubeconfig for the management cluster"

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "kubeconfig" {
  secret_id     = aws_secretsmanager_secret.kubeconfig.id
  secret_string = module.eks.kubeconfig
}

# Variables
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "flux_version" {
  description = "Flux Helm chart version"
  type        = string
  default     = "2.11.0"
}

variable "crossplane_version" {
  description = "Crossplane Helm chart version"
  type        = string
  default     = "1.14.0"
}

variable "route53_zone_arns" {
  description = "Route53 zone ARNs"
  type        = list(string)
  default     = ["arn:aws:route53:::hostedzone/*"]
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

# Outputs
output "cluster_endpoint" {
  description = "Management cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "Management cluster name"
  value       = module.eks.cluster_name
}

output "crossplane_role_arn" {
  description = "Crossplane IAM role ARN"
  value       = module.eks.crossplane_role_arn
}
