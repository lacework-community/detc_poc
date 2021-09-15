
output "cluster_id" {
  description = "EKS cluster id"
  value       = module.eks.cluster_id
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint for control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids for EKS cluster control plane"
  value       = module.eks.cluster_security_group_id
}

output "kubectl_config" {
  description = "kubectl config file"
  value       = module.eks.kubeconfig
}

output "config_map_aws_auth" {
  description = "Authenticate for the EKS cluster"
  value       = module.eks.config_map_aws_auth
}

output "region" {
  description = "EKS region"
  value       = var.AWS_REGION
}

output "cluster_name" {
  description = "EKS Cluster Name"
  value       = local.cluster_name
}