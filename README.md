# How to deploy AWS Infrastructure for ARTEXA

The AWS infrastructure for ARTEXA is defined in Terraform.
Terraform is an infrastructure-as-code (IaC) tool.
IaC codifies cloud APIs (e.g. AWS API) into declarative configuration files.

Cloud resources like the Kubernetes cluster are defined in `*.tf` files.
The Terraform declarations can be customized using variables.
Variables are defined in `*.tfvars` files.
Terraform reads the `*.tf` files and makes an execution plan which AWS resources to create and applies the changes.
The goal of the execution plan is to create the AWS infrastructure described in Terraform.
When the plan is applied, AWS resources that have been created by Terraform are stored in the Terraform state.
The Terraform state is a file that maps the virtual resources declared in `*.tf` to real AWS resources.
When you make changes to the Terraform declaration and apply the changes, Terraform compares the target state with the actual state and creates a new execution plan that only contains the changes to get from the current state to the target state.

Terraform is executed on an administration machine and will connect to the AWS APIs to create the AWS resources.

Here are the steps to do to create the AWS infrastructure. The single steps are explained in the remainder.

1.  Create and configure AWS access
1.  Setup Administration Machine
    1.  Create an AWS Bastion Host (optional)
    1.  Installation of Tools
    1.  Configure AWS CLI
1.  Setup Terraform
    1.  Create Terraform State Bucket
    1.  Create Secrets Manager Secrets
    1.  Adjust Terraform Variables
    1.  Apply Terraform Configuration

## Create and configure AWS access

-   **If you use AWS Security Credentials**
    -   Create an IAM User, e.g., `terraform-bastion` with sufficient permissions to create, update, delete all AWS resources that are created by Terraform.
    -   Create security credentials (access key, secret key) for this IAM User. Make sure you store the secret key in a safe location as it can be viewed only once.
-   **If you use AWS SSO**, make sure it has sufficient permission.

## Setup Administration Machine

On your administration machine, you need to install the following tools to deploy ARTEXA:

1. aws CLI (https://docs.aws.amazon.com/de_de/cli/latest/userguide/getting-started-install.html)
1. terraform
1. kubectl
1. helm

dSPACE recommends to use an execute Terraform from an [Linux Bastion Host](https://docs.aws.amazon.com/mwaa/latest/userguide/tutorials-private-network-bastion.html).
The setup of an AWS Bastion Host is described in the remainder.

### Create an AWS Bastion Host

-   Create an IAM Role, e.g., `terraform-bastion` for the Bastion Host and attach the policy `AmazonSSMManagedInstanceCore` to it.
-   Create an EC2 instance that will become the Bastion Host.

    -   It is recommended to use Amazon Linux as Amazon Machine Image (AMI).
    -   It is recommended to use an instance type with 4 vCPUs, 8 GB RAM (e.g. t3.xlarge)
    -   100 GB storage are recommended
    -   As IAM instance profile, select the IAM Role that you have created before. This will allow you to connect to the Linux Bastion Host using [Secure Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html).

-   Optional: If you plan to use a private EKS cluster endpoint you need to keep in mind that the Bastion and the EKS cluster need to be in the same VPC.
-   Optional: If you plan to connect to the Bastion via SSH, you need to create a Key pair for login and check the options **Auto-assign public IP** and **Allow SSH traffic**. Make sure that you store the .pem file in a safe location. You must ensure that your Amazon EKS control plane security group contains rules to allow ingress traffic on port 443 from your bastion host. Also, you must ensure that the security group of your Bastion host allows incoming traffic on port 22.

Here is an example on how to create an Bastion host using the AWS CLI.

```powershell
$imageid="ami-0592c673f0b1e7665"
$instancetype="t3.xlarge"
$keyname="terraform-bastion"
$subnetid="subnet-0589e800f6405d984"
$iaminstanceprofile="Arn=arn:aws:iam::123456789012:instance-profile/terraform-bastion"
$profile="123456789012_AdministratorAccess"
$blockdevicemappings="Ebs={DeleteOnTermination=true,VolumeSize=100GB,VolumeType=gp3}"
$tags="ResourceType=instance,Tags=[{Key=Name,Value=terraform-bastion}]"
$securitygroupids="sg-0ba1d8a64599759db"

aws ec2 run-instances `
--image-id $imageid `
--instance-type $instancetype `
--key-name $keyname `
--subnet-id $subnetid `
--iam-instance-profile $iaminstanceprofile `
--associate-public-ip-address `
--profile $profile `
--tag-specifications $tags `
--security-group-ids $securitygroupids `
--dry-run
```

```powershell
$profile="123456789012_AdministratorAccess"
cd Deploy
aws s3 sync ./instances/aws-qa s3://artexa-filetransfer/instances/aws-qa --exclude "secrets/*" --exclude "terraform/.terraform/*" --profile $profile --dryrun
aws s3 sync ./terraform s3://artexa-filetransfer/terraform --exclude ".terraform/*" --profile $profile --dryrun
```

You can connect to the bastion host from your administration machine using the AWS Session Manager. In this case you need to follow the instructions to [install Session Manager plugin for the AWS CLI](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html). After installing, you can create a session like this.

```powershell
aws ssm start-session --target "i-0ff045872de825c89" --profile "123456789012_AdministratorAccess"
```

Alternatively to Session Manager, you can use an SSH session.
Before establishing an SSH connection to your AWS Bastion, make sure that the security group of your Bastion host allows incoming traffic on port 22.

To open an interactive SSH terminal, run the following command, providing your keyfile `terraform-bastion.pem` and the public DNS name of the EC2 machine:

```powershell
ssh -i terraform-bastion.pem ec2-user@ec2-54-93-121-20.eu-central-1.compute.amazonaws.com
```

If you only want to forward the kubectl access from your local administration machine to the Bastion host using a [SOCKS5 proxy](https://kubernetes.io/docs/tasks/extend-kubernetes/socks5-proxy-access-api/#using-ssh-to-create-a-socks5-proxy), run the following command:

```powershell
ssh -i terraform-bastion.pem -D 1080 -q -N ec2-user@ec2-54-93-121-20.eu-central-1.compute.amazonaws.com
```

You also need to add the proxy url to the kubeconfig on your administration machine:

```diff
apiVersion: v1
clusters:
  - cluster:
      server: https://333063836D6E889C17193BF63BE0D2C5.gr7.eu-central-1.eks.amazonaws.com
+     proxy-url: socks5://localhost:1080
```

```bash
$profile="123456789012_AdministratorAccess"
aws s3 sync s3://artexa-filetransfer/terraform ~/terraform --profile $profile --dryrun
aws s3 sync s3://artexa-filetransfer/instances ~/instances --profile $profile --dryrun
```

### Installation of Tools (Amazon Linux Bastion Host)

-   AWS CLI is pre-installed on Amazon Linux, so you can skip this step.
-   To install Terraform on Amazon Linux, run the following commands (see [https://developer.hashicorp.com/terraform/install#linux](https://developer.hashicorp.com/terraform/install#linux))

```bash
sudo yum install -y yum-utils shadow-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install terraform-1.4.7
```

-   To install kubectl on Amazon Linux, run the following commands (see [https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-kubectl-binary-with-curl-on-linux](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-kubectl-binary-with-curl-on-linux)

```bash
sudo curl -LO "https://dl.k8s.io/release/$(sudo curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

-   To install helm on Amazon Linux, run the following commands (see [https://helm.sh/docs/intro/install/#from-script](https://helm.sh/docs/intro/install/#from-script)):

```bash
sudo curl -sLO https://get.helm.sh/helm-v3.15.2-linux-amd64.tar.gz
sudo tar -zxvf helm-v3.15.2-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm
```

-   Verify the tool installations:

```bash
aws --version
terraform --version
kubectl version
helm version
```

### Configure AWS CLI

-   You need to configure an AWS profile for your AWS account.
-   **If you do not use AWS Security Credentials**
    -   Run the command `aws configure` and enter the access and secret keys of your IAM user.
-   **If you use AWS SSO**
    -   Open the AWS access portal for your company (e.g., https://xxxx.awsapps.com/start), select the AWS account where you want deploy ARTEXA into, click on `access keys`, and note the following values: sso_region, sso_account_id, sso_role_name.
    -   If it does not exist, create the file `~/.aws/config` on your administration machine where `~` is the home directory of your current user. Then add the profile configuration to the `~/.aws/config`. On Linux, you can use the following command to do this:

```bash
cat > ~/.aws/config << EOF
[profile 123456789012_AdministratorAccess]
region = eu-central-1
output = json
sso_start_url = https://ssocontroltower.awsapps.com/start
sso_region = eu-central-1
sso_account_id = 123456789012
sso_role_name = AdministratorAccess
EOF
```

Remark: Please do **not** use the command `aws configure sso` because it uses SSO sessions that are not supported by Terraform.

## Setup Terraform

### Create Terraform State Bucket

Per default, the Terraform state is stored in a file `*.tfstate` on your local hard drive.
It is recommended to store the Terraform state in an remote S3 bucket.

To store the Terraform to an S3 bucket, you have to manually create it first.
The bucket name needs to be globally unique, e.g. `artexa-terraform-state`.

After you have created the bucket, you need to link it with Terraform:
To do so, please make a copy of the file `backend.config.template`, name it `backend.config` and open the file in a text editor. The values have to point to an existing S3 bucket to be used to store the Terraform state:

```hcl
bucket = "artexa-terraform-state"
key    = "development.tfstate"
region = "eu-central-1"
profile= "123456789012_AdministratorAccess"
```

Run the following command to download any Terraform dependencies and apply the backend configuration:

```pwsh
terraform init -backend-config="./backend.config"
```

### Create Secrets Manager Secrets

Username and password for the PostgreSQL databases are stored in AWS Secrets Manager.
Before you let Terraform create AWS resources, you need to manually create a Secrets Manager secret that stores the username and password.
It is recommended to create individual secrets per ARTEXA instance (e.g. production and staging instance).
To create the secret, open the Secrets Manager console and click the button `Store a new secret`.
As secret type choose `Other type of secret`.
The password must contain from 8 to 128 characters and must not contain any of the following: / (slash), '(single quote), "(double quote) and @ (at sign).
Open the Plaintext tab and paste the following JSON object and enter your usernames and passwords:

```json
{
    "postgresql_password": "<your password>"
}
```

Alternatively, you can create the secret with the following PowerShell script:

```powershell
$region = Read-Host "Enter AWS region"
$secretname = Read-Host "Enter secret name"
$password = Read-Host "Enter PostgreSQL password"
$profile = Read-Host "Enter AWS profile name"
$postgresqlCredentials = @"
{
    "postgresql_password" : "$password"
}
"@ | ConvertFrom-Json | ConvertTo-Json -Compress
$postgresqlCredentials = $postgresqlCredentials -replace '([\\]*)"', '$1$1\"'
aws secretsmanager create-secret --name $secretname --secret-string $postgresqlCredentials --region $region --profile $profile
```

### Adjust Terraform Variables

For your configuration, please rename the template file `terraform.tfvars` to `my-terraform.tfvars` and open it in a text editor.
This file contains all variables that are configurable including documentation of the variables. Please adapt the values before you deploy the resources.

```diff
artexa_instances = {
  "production" = {
+    secretname = "<secret name>"
    }
}
```

Also rename the file `providers.tf.template` to `main.tf` and fill in the name of the AWS profile you have created before.

```diff
provider "aws" {
+  profile = "<profile-name>"
}
```

-   **If you use AWS SSO**, add the ARN of your SSO IAM role to `.tfvars`:

```hcl
map_roles = [{
  groups   = ["system:masters"]
  rolearn  = "arn:aws:iam::123456789012:role/AWSReservedSSO_AdministratorAccess_dda893720a26446d"
  username = "admin"
  },
]
```

-   **If you use AWS Security Credentials**, add the ARN of your IAM user to the `.tfvars`:

```hcl
map_users = [{
  groups   = ["system:masters"]
  userarn  = "arn:aws:iam::123456789012:user/terraform"
  username = "terraform"
}]
```

-   **If you use a preconfigured VPC**, provide the ids of the VPC and its respective subnets:

```hcl
vpcId = "vpc-08a57d82585de2bb8"
public_subnet_filter  = [{ name = "subnet-id", values = ["subnet-0589e800f6405d984", "subnet-0fa0c652281451c1f", ] }]
private_subnet_filter = [{ name = "subnet-id", values = ["subnet-04a9d20fc26e8b9df", "subnet-0011bbfe23da556cd"] }]
```

Make sure that your preconfigured subnets fulfill the [subnet requirements for nodes](https://docs.aws.amazon.com/eks/latest/userguide/network-reqs.html#node-subnet-reqs), i.e.,
all subnets need the tag `kubernetes.io/cluster/<infrastructurename>=shared`,
private subnets need the tag `kubernetes.io/role/internal-elb=1`,
public subnets need the tag `kubernetes.io/role/elb=1`,

## Apply Terraform Configuration

-   _If you use AWS SSO_, start a new SSO session:

```pwsh
aws sso login --profile 123456789012_AdministratorAccess
```

-   Apply the Terraform configuration with your variables:

```pwsh
terraform apply --var-file="./my-terraform.tfvars"
```

Inspect the Terraform execution plan and apply it with `yes`.

## Backup and Restore

ARTEXA stores data in the PostgreSQL database and in S3 buckets that needs to be backed up.
AWS supports continuous backups for Amazon RDS for PostgreSQL and S3 that allows point-in-time recovery.
[Point-in-time recovery](https://docs.aws.amazon.com/aws-backup/latest/devguide/point-in-time-recovery.html) lets you restore your data to any point in time within a defined retention period.

The ARTEXA reference architecture creates an AWS backup plan that makes continuous backups of the PostgreSQL database and S3 buckets.
The backups are stored in an AWS backup vault per ARTEXA instance.
An IAM role is also automatically created that has proper permissions to create backups.
To enable backups for your ARTEXA instance, make sure you have the flag `enable_backup_service` set in your `.tfvars` file:

```hcl
artexa_instances = {
  "production" = {
        enable_backup_service    = true
    }
}
```

### Amazon RDS for PostgreSQL

Create a new target RDS instance (backup server) that is a copy of a source RDS instance (production server) of a specific point-in-time.
The command [`restore-db-instance-to-point-in-time`](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/rds/restore-db-instance-to-point-in-time.html) creates the target database.
Most of the configuration settings are copied from the source database.
To be able to connect to the target instance the easiest way is to explicitly set the same security group and subnet group as used for the source instance.

Restoring an RDS instance can be done via Powershell as described in the remainder:

```bash
aws rds restore-db-instance-to-point-in-time --source-db-instance-identifier artexa-production-artexa --target-db-instance artexa-production-artexa-backup --vpc-security-group-ids sg-0b954a0e25cd11b6d --db-subnet-group-name artexa-reference-vpc --restore-time 2022-06-16T23:45:00.000Z --tags Key=timestamp,Value=2022-06-16T23:45:00.000Z
```

Adjust the namespace and path to the kubeconfig file in the following command.
The command creates a pgdump pod using the standard postgres image and open a bash:

```bash
kubectl run pgdump -ti -n your-namespace --image postgres --kubeconfig ./path/to/your/kube.config -- bash
```

In the pod's Bash, use the pg_dump and pg_restore commands to stream the data from the backup server to the production server:

```bash
pg_dump -h artexa-production-artexa-backup.cexy8brfkmxk.eu-central-1.rds.amazonaws.com -p 5432 -U dbuser -Fc artexa | pg_restore --clean --if-exists -h artexa-production-artexa.cexy8brfkmxk.eu-central-1.rds.amazonaws.com -p 5432 -U dbuser -d artexa
```

Alternatively, you can [restore the RDS instance via the AWS console](https://docs.aws.amazon.com/aws-backup/latest/devguide/restoring-rds.html).

### S3

The ARTEXA reference architecture creates an S3 bucket for artifacts and enables versioning of the S3 bucket which is a requirement for point-in-time recovery.

To restore the S3 buckets to an older version you need to create an IAM role that has proper permissions:

```powershell
$rolename = "restore-role"
$trustrelation = @"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": ["sts:AssumeRole"],
      "Effect": "allow",
      "Principal": {
        "Service": ["backup.amazonaws.com"]
      }
    }
  ]
}
"@
echo $trustrelation > trust.json
aws iam create-role --role-name $rolename --assume-role-policy-document file://trust.json --description "Role to restore"
aws iam attach-role-policy --role-name $rolename --policy-arn="arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Restore"
aws iam attach-role-policy --role-name $rolename --policy-arn="arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
$rolearn=aws iam get-role --role-name $rolename --query 'Role.Arn'
```

Restoring an S3 bucket can be done via Powershell as described in the remainder:
You can restore the S3 data in-place, into another existing bucket, or into a new bucket.

```powershell
$uuid = New-Guid
$metadata = @"
{
  "DestinationBucketName": "artexa-production-pkg-backup",
  "NewBucket": "true",
  "RestoreTime": "2022-06-20T23:45:00.000Z",
  "Encrypted": "false",
  "CreationToken": "$uuid"
}
"@
$metadata = $metadata -replace '([\\]*)"', '$1$1\"'
aws backup start-restore-job `
--recovery-point-arn "arn:aws:backup:eu-central-1:012345678901:recovery-point:continuous:artexa-production-pkg-0f51c39b" `
--iam-role-arn $rolearn `
--metadata $metadata
```

Alternatively, you can [restore the S3 data via the AWS console](https://docs.aws.amazon.com/aws-backup/latest/devguide/restoring-s3.html).

<!-- prettier-ignore-start -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.1.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 5.70.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | 2.15.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | 2.32.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.60.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_artexa_instance"></a> [artexa\_instance](#module\_artexa\_instance) | ./modules/artexa-aws-instance | n/a |
| <a name="module_eks"></a> [eks](#module\_eks) | git::https://github.com/aws-ia/terraform-aws-eks-blueprints.git | v4.32.1 |
| <a name="module_eks-addons"></a> [eks-addons](#module\_eks-addons) | git::https://github.com/aws-ia/terraform-aws-eks-blueprints.git//modules/kubernetes-addons | v4.32.1 |
| <a name="module_security_group"></a> [security\_group](#module\_security\_group) | terraform-aws-modules/security-group/aws | 5.1.1 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | 5.5.3 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_instance_profile.license_server_profile](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/resources/iam_instance_profile) | resource |
| [aws_iam_policy.license_server_policy](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/resources/iam_policy) | resource |
| [aws_iam_role.license_server_role](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.license_server_ssm](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.s3_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/resources/iam_role_policy_attachment) | resource |
| [aws_instance.license_server](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/resources/instance) | resource |
| [aws_lb.application-loadbalancer](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/resources/lb) | resource |
| [aws_lb_listener.httplistener](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/resources/lb_listener) | resource |
| [aws_lb_listener.httpslistener](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/resources/lb_listener) | resource |
| [aws_lb_target_group.targetgroup](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/resources/lb_target_group) | resource |
| [aws_s3_bucket.license_server_bucket](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_policy.ssl_only_policy](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/resources/s3_bucket_policy) | resource |
| [aws_security_group.alb-sg](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/resources/security_group) | resource |
| [aws_security_group.allow_codemeter](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/resources/security_group) | resource |
| [aws_ssm_maintenance_window.install](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/resources/ssm_maintenance_window) | resource |
| [aws_ssm_maintenance_window.scan](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/resources/ssm_maintenance_window) | resource |
| [aws_ssm_maintenance_window_target.install](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/resources/ssm_maintenance_window_target) | resource |
| [aws_ssm_maintenance_window_target.scan](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/resources/ssm_maintenance_window_target) | resource |
| [aws_ssm_maintenance_window_target.scan_eks_nodes](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/resources/ssm_maintenance_window_target) | resource |
| [aws_ssm_maintenance_window_task.install](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/resources/ssm_maintenance_window_task) | resource |
| [aws_ssm_maintenance_window_task.scan](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/resources/ssm_maintenance_window_task) | resource |
| [aws_ssm_patch_baseline.production](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/resources/ssm_patch_baseline) | resource |
| [aws_ssm_patch_group.patch_group](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/resources/ssm_patch_group) | resource |
| [aws_ami.amazon_linux_kernel5](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/data-sources/ami) | data source |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/data-sources/region) | data source |
| [aws_subnet.private_subnet](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/data-sources/subnet) | data source |
| [aws_subnet.public_subnet](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/data-sources/subnet) | data source |
| [aws_subnets.private_subnets](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/data-sources/subnets) | data source |
| [aws_subnets.public_subnets](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/data-sources/subnets) | data source |
| [aws_vpc.preconfigured](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application_loadbalancer"></a> [application\_loadbalancer](#input\_application\_loadbalancer) | Deploy an AWS Application Loadbalancer | `bool` | `false` | no |
| <a name="input_artexa_instances"></a> [artexa\_instances](#input\_artexa\_instances) | A list containing the individual ARTEXA instances, such as 'staging' and 'production'. | <pre>map(object({<br>    name                         = string<br>    postgresqlVersion            = string<br>    postgresqlStorage            = number<br>    postgresqlMaxStorage         = number<br>    db_instance_type_artexa      = string<br>    postgresqlStorageKeycloak    = number<br>    postgresqlMaxStorageKeycloak = number<br>    db_instance_type_keycloak    = string<br>    secretname                   = string<br>    enable_deletion_protection   = bool<br>    enable_backup_service        = bool<br>    enable_irsa                  = bool<br>    backup_retention             = number<br>    enable_keycloak              = bool<br>    k8s_namespace                = string<br><br>  }))</pre> | <pre>{<br>  "production": {<br>    "backup_retention": 7,<br>    "db_instance_type_artexa": "db.t3.large",<br>    "db_instance_type_keycloak": "db.t3.large",<br>    "enable_backup_service": true,<br>    "enable_deletion_protection": true,<br>    "enable_irsa": true,<br>    "enable_keycloak": true,<br>    "k8s_namespace": "artexa",<br>    "name": "production",<br>    "postgresqlMaxStorage": 100,<br>    "postgresqlMaxStorageKeycloak": 100,<br>    "postgresqlStorage": 20,<br>    "postgresqlStorageKeycloak": 20,<br>    "postgresqlVersion": "16",<br>    "secretname": "aws-artexa-dev-production"<br>  }<br>}</pre> | no |
| <a name="input_certificate_arn"></a> [certificate\_arn](#input\_certificate\_arn) | TLS certificate ARN. Only required when application\_loadbalancer is true. | `string` | `""` | no |
| <a name="input_cluster_endpoint_private_access"></a> [cluster\_endpoint\_private\_access](#input\_cluster\_endpoint\_private\_access) | Indicates whether or not the EKS private API server endpoint is enabled. Default to EKS resource and it is false | `bool` | `false` | no |
| <a name="input_cluster_endpoint_public_access"></a> [cluster\_endpoint\_public\_access](#input\_cluster\_endpoint\_public\_access) | Indicates whether or not the EKS public API server endpoint is enabled. Default to EKS resource and it is true | `bool` | `true` | no |
| <a name="input_cluster_endpoint_public_access_cidrs"></a> [cluster\_endpoint\_public\_access\_cidrs](#input\_cluster\_endpoint\_public\_access\_cidrs) | List of CIDR blocks which can access the Amazon EKS public API server endpoint | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| <a name="input_codemeter"></a> [codemeter](#input\_codemeter) | Download link for codemeter rpm package. | `string` | `"https://www.wibu.com/support/user/user-software/file/download/13346.html?tx_wibudownloads_downloadlist%5BdirectDownload%5D=directDownload&tx_wibudownloads_downloadlist%5BuseAwsS3%5D=0&cHash=8dba7ab094dec6267346f04fce2a2bcd"` | no |
| <a name="input_enable_patching"></a> [enable\_patching](#input\_enable\_patching) | Scans license server EC2 instance and EKS nodes for updates. Installs patches on license server automatically. EKS nodes need to be updated manually. | `bool` | `false` | no |
| <a name="input_infrastructurename"></a> [infrastructurename](#input\_infrastructurename) | The name of the infrastructure. | `string` | `"artexa"` | no |
| <a name="input_install_schedule"></a> [install\_schedule](#input\_install\_schedule) | 6-field Cron expression describing the install maintenance schedule. Must not overlap with variable scan\_schedule. | `string` | `"cron(0 3 * * ? *)"` | no |
| <a name="input_kubernetesVersion"></a> [kubernetesVersion](#input\_kubernetesVersion) | The version of the EKS cluster. | `string` | `"1.29"` | no |
| <a name="input_license_server"></a> [license\_server](#input\_license\_server) | Specifies whether a license server VM will be created. | `bool` | `false` | no |
| <a name="input_license_server_type"></a> [license\_server\_type](#input\_license\_server\_type) | EC2 Instance type of the license server. | `string` | `"t3a.medium"` | no |
| <a name="input_linuxNodeCountMax"></a> [linuxNodeCountMax](#input\_linuxNodeCountMax) | The maximum number of Linux nodes for the regular services | `number` | `12` | no |
| <a name="input_linuxNodeCountMin"></a> [linuxNodeCountMin](#input\_linuxNodeCountMin) | The minimum number of Linux nodes for the regular services | `number` | `1` | no |
| <a name="input_linuxNodeSize"></a> [linuxNodeSize](#input\_linuxNodeSize) | The machine size of the Linux nodes for the regular services | `list(string)` | <pre>[<br>  "m5a.4xlarge",<br>  "m5a.8xlarge"<br>]</pre> | no |
| <a name="input_maintainance_duration"></a> [maintainance\_duration](#input\_maintainance\_duration) | How long in hours for the maintenance window. | `number` | `3` | no |
| <a name="input_map_accounts"></a> [map\_accounts](#input\_map\_accounts) | Additional AWS account numbers to add to the aws-auth ConfigMap | `list(string)` | `[]` | no |
| <a name="input_map_roles"></a> [map\_roles](#input\_map\_roles) | Additional IAM roles to add to the aws-auth ConfigMap | <pre>list(object({<br>    rolearn  = string<br>    username = string<br>    groups   = list(string)<br>  }))</pre> | `[]` | no |
| <a name="input_map_users"></a> [map\_users](#input\_map\_users) | Additional IAM users to add to the aws-auth ConfigMap | <pre>list(object({<br>    userarn  = string<br>    username = string<br>    groups   = list(string)<br>  }))</pre> | `[]` | no |
| <a name="input_private_subnet_filter"></a> [private\_subnet\_filter](#input\_private\_subnet\_filter) | Tag filter | <pre>list(object({<br>    name   = string<br>    values = list(string)<br>  }))</pre> | <pre>[<br>  {<br>    "name": "subnet-id",<br>    "values": [<br>      "subnet-0490ffe38d62c4c4c"<br>    ]<br>  }<br>]</pre> | no |
| <a name="input_public_subnet_filter"></a> [public\_subnet\_filter](#input\_public\_subnet\_filter) | Tag filter | <pre>list(object({<br>    name   = string<br>    values = list(string)<br>  }))</pre> | <pre>[<br>  {<br>    "name": "subnet-id",<br>    "values": [<br>      "subnet-0490ffe38d62c4c4c"<br>    ]<br>  }<br>]</pre> | no |
| <a name="input_region"></a> [region](#input\_region) | The AWS region to be used. | `string` | `"eu-central-1"` | no |
| <a name="input_scan_schedule"></a> [scan\_schedule](#input\_scan\_schedule) | 6-field Cron expression describing the scan maintenance schedule. Must not overlap with variable install\_schedule. | `string` | `"cron(0 0 * * ? *)"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | The tags to be added to all resources. | `map(any)` | `{}` | no |
| <a name="input_vpcCidr"></a> [vpcCidr](#input\_vpcCidr) | The CIDR for the virtual private cluster. | `string` | `"10.1.0.0/18"` | no |
| <a name="input_vpcId"></a> [vpcId](#input\_vpcId) | The ID of preconfigured VPC. Empty string will create a new VPC. Check the subnet requirements for nodes https://docs.aws.amazon.com/eks/latest/userguide/network-reqs.html#node-subnet-reqs. | `string` | `""` | no |
| <a name="input_vpcPrivateSubnets"></a> [vpcPrivateSubnets](#input\_vpcPrivateSubnets) | List of CIDRs for the private subnets. | `list(any)` | <pre>[<br>  "10.1.0.0/22",<br>  "10.1.4.0/22",<br>  "10.1.8.0/22"<br>]</pre> | no |
| <a name="input_vpcPublicSubnets"></a> [vpcPublicSubnets](#input\_vpcPublicSubnets) | List of CIDRs for the public subnets. | `list(any)` | <pre>[<br>  "10.1.12.0/22",<br>  "10.1.16.0/22",<br>  "10.1.20.0/22"<br>]</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_application_loadbalancer"></a> [application\_loadbalancer](#output\_application\_loadbalancer) | DNS name of the Application Loadbalancer |
| <a name="output_artexa_instances"></a> [artexa\_instances](#output\_artexa\_instances) | n/a |
| <a name="output_eks_cluster_id"></a> [eks\_cluster\_id](#output\_eks\_cluster\_id) | Amazon EKS Cluster Name |
| <a name="output_license_server"></a> [license\_server](#output\_license\_server) | Private DNS name of the license server |
<!-- END_TF_DOCS -->
<!-- prettier-ignore-end -->
