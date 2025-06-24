

# Deploy an AWS Application Loadbalancer
application_loadbalancer = false

# A list containing the individual ARTEXA instances, such as 'staging' and 'production'.
artexa_instances = {
  "production": {
    "backup_retention": 7,
    "db_instance_type_artexa": "db.t3.large",
    "db_instance_type_keycloak": "db.t3.large",
    "enable_backup_service": true,
    "enable_deletion_protection": true,
    "enable_irsa": true,
    "enable_keycloak": true,
    "k8s_namespace": "artexa",
    "name": "production",
    "postgresqlMaxStorage": 100,
    "postgresqlMaxStorageKeycloak": 100,
    "postgresqlStorage": 20,
    "postgresqlStorageKeycloak": 20,
    "postgresqlVersion": "16",
    "secretname": "aws-artexa-dev-production"
  }
}

# TLS certificate ARN. Only required when application_loadbalancer is true.
certificate_arn = ""

# Indicates whether or not the EKS private API server endpoint is enabled. Default to EKS resource and it is false
cluster_endpoint_private_access = false

# Indicates whether or not the EKS public API server endpoint is enabled. Default to EKS resource and it is true
cluster_endpoint_public_access = true

# List of CIDR blocks which can access the Amazon EKS public API server endpoint
cluster_endpoint_public_access_cidrs = [
  "0.0.0.0/0"
]

# Download link for codemeter rpm package.
codemeter = "https://www.wibu.com/support/user/user-software/file/download/13346.html?tx_wibudownloads_downloadlist%5BdirectDownload%5D=directDownload&tx_wibudownloads_downloadlist%5BuseAwsS3%5D=0&cHash=8dba7ab094dec6267346f04fce2a2bcd"

# Scans license server EC2 instance and EKS nodes for updates. Installs patches on license server automatically. EKS nodes need to be updated manually.
enable_patching = false

# The name of the infrastructure.
infrastructurename = "artexa"

# 6-field Cron expression describing the install maintenance schedule. Must not overlap with variable scan_schedule.
install_schedule = "cron(0 3 * * ? *)"

# The version of the EKS cluster.
kubernetesVersion = "1.29"

# Specifies whether a license server VM will be created.
license_server = false

# EC2 Instance type of the license server.
license_server_type = "t3a.medium"

# The maximum number of Linux nodes for the regular services
linuxNodeCountMax = 12

# The minimum number of Linux nodes for the regular services
linuxNodeCountMin = 1

# The machine size of the Linux nodes for the regular services
linuxNodeSize = [
  "m5a.4xlarge",
  "m5a.8xlarge"
]

# How long in hours for the maintenance window.
maintainance_duration = 3

# Additional AWS account numbers to add to the aws-auth ConfigMap
map_accounts = []

# Additional IAM roles to add to the aws-auth ConfigMap
map_roles = []

# Additional IAM users to add to the aws-auth ConfigMap
map_users = []

# Tag filter
private_subnet_filter = [
  {
    "name": "subnet-id",
    "values": [
      "subnet-0490ffe38d62c4c4c"
    ]
  }
]

# Tag filter
public_subnet_filter = [
  {
    "name": "subnet-id",
    "values": [
      "subnet-0490ffe38d62c4c4c"
    ]
  }
]

# The AWS region to be used.
region = "eu-central-1"

# 6-field Cron expression describing the scan maintenance schedule. Must not overlap with variable install_schedule.
scan_schedule = "cron(0 0 * * ? *)"

# The tags to be added to all resources.
tags = {}

# The CIDR for the virtual private cluster.
vpcCidr = "10.1.0.0/18"

# The ID of preconfigured VPC. Empty string will create a new VPC. Check the subnet requirements for nodes https://docs.aws.amazon.com/eks/latest/userguide/network-reqs.html#node-subnet-reqs.
vpcId = ""

# List of CIDRs for the private subnets.
vpcPrivateSubnets = [
  "10.1.0.0/22",
  "10.1.4.0/22",
  "10.1.8.0/22"
]

# List of CIDRs for the public subnets.
vpcPublicSubnets = [
  "10.1.12.0/22",
  "10.1.16.0/22",
  "10.1.20.0/22"
]