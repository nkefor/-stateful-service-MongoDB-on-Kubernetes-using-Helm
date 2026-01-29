# EKS Module Variables

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "environment" {
  description = "Environment name (development, staging, production)"
  type        = string
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be one of: development, staging, production."
  }
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "enable_public_endpoint" {
  description = "Enable public API endpoint"
  type        = bool
  default     = true
}

# System Node Group
variable "system_node_instance_types" {
  description = "Instance types for system node group"
  type        = list(string)
  default     = ["m6i.large"]
}

variable "system_node_min_size" {
  description = "Minimum number of system nodes"
  type        = number
  default     = 2
}

variable "system_node_max_size" {
  description = "Maximum number of system nodes"
  type        = number
  default     = 4
}

variable "system_node_desired_size" {
  description = "Desired number of system nodes"
  type        = number
  default     = 2
}

# Application Node Group
variable "app_node_instance_types" {
  description = "Instance types for application node group"
  type        = list(string)
  default     = ["m6i.xlarge"]
}

variable "app_node_min_size" {
  description = "Minimum number of application nodes"
  type        = number
  default     = 2
}

variable "app_node_max_size" {
  description = "Maximum number of application nodes"
  type        = number
  default     = 10
}

variable "app_node_desired_size" {
  description = "Desired number of application nodes"
  type        = number
  default     = 3
}

# Route53 Zones for External DNS
variable "route53_zone_arns" {
  description = "Route53 hosted zone ARNs for External DNS"
  type        = list(string)
  default     = ["arn:aws:route53:::hostedzone/*"]
}

# Crossplane
variable "enable_crossplane" {
  description = "Enable Crossplane IRSA role (for management cluster)"
  type        = bool
  default     = false
}

# Tags
variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
