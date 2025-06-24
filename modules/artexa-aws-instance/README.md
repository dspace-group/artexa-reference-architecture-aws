<!-- prettier-ignore-start -->
<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_backup_plan.backup-plan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_plan) | resource |
| [aws_backup_selection.backup-selection-rds-s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_selection) | resource |
| [aws_backup_vault.backup-vault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault) | resource |
| [aws_db_instance.artexa](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) | resource |
| [aws_db_instance.keycloak](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) | resource |
| [aws_db_subnet_group.database](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |
| [aws_iam_policy.s3_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.backup_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.rds_enhanced_monitoring_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.backup_rds_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.backup_s3_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.rds_enhanced_monitoring_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_s3_bucket.bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.bucketlogs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_logging.logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_policy.s3_log_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_policy.ssl_only_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.bucket_access_block](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.bucket_encryption](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.bucket_versioning](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_service_account.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |
| [aws_secretsmanager_secret.secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |
| [aws_secretsmanager_secret_version.secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_backup_retention"></a> [backup\_retention](#input\_backup\_retention) | The retention period for continuous backups can be between 1 and 35 days. | `number` | `7` | no |
| <a name="input_db_instance_type_artexa"></a> [db\_instance\_type\_artexa](#input\_db\_instance\_type\_artexa) | PostgreSQL database instance type for ARTEXA data | `string` | `"db.t3.large"` | no |
| <a name="input_db_instance_type_keycloak"></a> [db\_instance\_type\_keycloak](#input\_db\_instance\_type\_keycloak) | PostgreSQL database instance type for Keycloak data | `string` | `"db.t3.large"` | no |
| <a name="input_eks_oidc_issuer_url"></a> [eks\_oidc\_issuer\_url](#input\_eks\_oidc\_issuer\_url) | The URL on the EKS cluster OIDC Issuer | `string` | n/a | yes |
| <a name="input_eks_oidc_provider_arn"></a> [eks\_oidc\_provider\_arn](#input\_eks\_oidc\_provider\_arn) | The ARN of the OIDC Provider. | `string` | n/a | yes |
| <a name="input_enable_backup_service"></a> [enable\_backup\_service](#input\_enable\_backup\_service) | n/a | `bool` | `false` | no |
| <a name="input_enable_deletion_protection"></a> [enable\_deletion\_protection](#input\_enable\_deletion\_protection) | Enable deletion protection for databases. | `bool` | `true` | no |
| <a name="input_enable_irsa"></a> [enable\_irsa](#input\_enable\_irsa) | Create IAM roles for service accounts | `bool` | `true` | no |
| <a name="input_enable_keycloak"></a> [enable\_keycloak](#input\_enable\_keycloak) | Set to true when Keycloak is used as authorization server for ARTEXA | `bool` | `true` | no |
| <a name="input_infrastructurename"></a> [infrastructurename](#input\_infrastructurename) | The name of the infrastructure. | `string` | n/a | yes |
| <a name="input_k8s_namespace"></a> [k8s\_namespace](#input\_k8s\_namespace) | Kubernetes namespace of the ARTEXA instance | `string` | `"artexa"` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the ARTEXA instance. e.g. production | `string` | n/a | yes |
| <a name="input_postgresqlMaxStorage"></a> [postgresqlMaxStorage](#input\_postgresqlMaxStorage) | The upper limit to which Amazon RDS can automatically scale the storage of the ARTEXA database. Must be greater than or equal to postgresqlStorage or 0 to disable Storage Autoscaling. | `number` | `20` | no |
| <a name="input_postgresqlMaxStorageKeycloak"></a> [postgresqlMaxStorageKeycloak](#input\_postgresqlMaxStorageKeycloak) | The upper limit to which Amazon RDS can automatically scale the storage of the Keycloak database. Must be greater than or equal to postgresqlStorage or 0 to disable Storage Autoscaling. | `number` | `20` | no |
| <a name="input_postgresqlStorage"></a> [postgresqlStorage](#input\_postgresqlStorage) | PostgreSQL Storage in GiB for ARTEXA. | `number` | `20` | no |
| <a name="input_postgresqlStorageKeycloak"></a> [postgresqlStorageKeycloak](#input\_postgresqlStorageKeycloak) | PostgreSQL Storage in GiB for Keycloak. The minimum value is 100 GiB and the maximum value is 65.536 GiB | `number` | `20` | no |
| <a name="input_postgresqlVersion"></a> [postgresqlVersion](#input\_postgresqlVersion) | PostgreSQL Server version to deploy | `string` | `"11"` | no |
| <a name="input_postgresql_security_group_id"></a> [postgresql\_security\_group\_id](#input\_postgresql\_security\_group\_id) | The ID of the security group | `string` | n/a | yes |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | List of subnet ids. | `list(any)` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The AWS region to be used. | `string` | `"eu-central-1"` | no |
| <a name="input_secretname"></a> [secretname](#input\_secretname) | Secrets manager secret | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | The tags to be added to all resources. | `map(any)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_artexa_instance"></a> [artexa\_instance](#output\_artexa\_instance) | Instance |
<!-- END_TF_DOCS -->
<!-- prettier-ignore-end -->
