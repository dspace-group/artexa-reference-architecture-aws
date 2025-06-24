locals {
  secret_postgres_username = "dbuser" # username is hardcoded because changing the username forces replacement of the db instance
  secrets                  = jsondecode(data.aws_secretsmanager_secret_version.secrets.secret_string)
  instancename             = join("-", [var.infrastructurename, var.name])
  db_artexa_id             = "${local.instancename}-artexa"
  db_keycloak_id           = "${local.instancename}-keycloak"
  eks_oidc_issuer          = replace(var.eks_oidc_issuer_url, "https://", "")
  k8s_namespace            = var.k8s_namespace
  models_serviceaccount    = "artexa-models-sa"
  backup_resources         = [aws_db_instance.artexa.arn, aws_s3_bucket.bucket.arn]
  backup_vault_name        = "${local.instancename}-backup-vault"
}

