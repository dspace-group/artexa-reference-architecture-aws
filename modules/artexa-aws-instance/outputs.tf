

output "artexa_instance" {
  description = "Instance"
  value = {
    database_artexa   = aws_db_instance.artexa.address
    database_keycloak = var.enable_keycloak ? aws_db_instance.keycloak[0].address : null
    bucket            = aws_s3_bucket.bucket.bucket
    k8s_namespace     = var.k8s_namespace
  }
}
