# EKS Module Outputs

output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data"
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for the cluster"
  value       = module.eks.cluster_oidc_issuer_url
}

output "cluster_oidc_provider_arn" {
  description = "OIDC provider ARN for IRSA"
  value       = module.eks.oidc_provider_arn
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "node_security_group_id" {
  description = "Security group ID attached to the EKS nodes"
  value       = module.eks.node_security_group_id
}

# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnets
}

# IRSA Role ARNs
output "cluster_autoscaler_role_arn" {
  description = "IAM role ARN for Cluster Autoscaler"
  value       = module.cluster_autoscaler_irsa.iam_role_arn
}

output "external_dns_role_arn" {
  description = "IAM role ARN for External DNS"
  value       = module.external_dns_irsa.iam_role_arn
}

output "lb_controller_role_arn" {
  description = "IAM role ARN for Load Balancer Controller"
  value       = module.lb_controller_irsa.iam_role_arn
}

output "crossplane_role_arn" {
  description = "IAM role ARN for Crossplane"
  value       = var.enable_crossplane ? module.crossplane_irsa[0].iam_role_arn : null
}

# Kubeconfig
output "kubeconfig" {
  description = "kubectl config for the cluster"
  value = <<-EOT
    apiVersion: v1
    kind: Config
    clusters:
    - cluster:
        server: ${module.eks.cluster_endpoint}
        certificate-authority-data: ${module.eks.cluster_certificate_authority_data}
      name: ${module.eks.cluster_name}
    contexts:
    - context:
        cluster: ${module.eks.cluster_name}
        user: ${module.eks.cluster_name}
      name: ${module.eks.cluster_name}
    current-context: ${module.eks.cluster_name}
    users:
    - name: ${module.eks.cluster_name}
      user:
        exec:
          apiVersion: client.authentication.k8s.io/v1beta1
          command: aws
          args:
          - eks
          - get-token
          - --cluster-name
          - ${module.eks.cluster_name}
          - --region
          - ${data.aws_region.current.name}
  EOT
  sensitive = true
}
