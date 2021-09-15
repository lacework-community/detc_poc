output "region" {
  value       = var.GCP_REGION
  description = "GCloud Region"
}

output "project_id" {
  value       = var.GCP_PROJECT_ID
  description = "GCloud Project ID"
}

output "kubernetes_cluster_name" {
  value       = google_container_cluster.primary.name
  description = "GKE Cluster Name"
}

output "kubernetes_cluster_host" {
  value       = google_container_cluster.primary.endpoint
  description = "GKE Cluster Host"
}