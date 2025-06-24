
output "artexa_instances" {
  description = ""
  value       = { for name, instance in module.artexa_instance : name => instance.artexa_instance }
}

output "eks_cluster_id" {
  description = "Amazon EKS Cluster Name"
  value       = module.eks.eks_cluster_id
}

output "license_server" {
  description = "Private DNS name of the license server"
  value       = var.license_server ? aws_instance.license_server[0].private_dns : ""
}

output "application_loadbalancer" {
  description = "DNS name of the Application Loadbalancer"
  value       = var.application_loadbalancer ? aws_lb.application-loadbalancer[0].dns_name : ""
}
