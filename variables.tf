variable "region" {
  type        = string
  description = "The AWS region to be used."
  default     = "eu-central-1"
}

variable "tags" {
  type        = map(any)
  description = "The tags to be added to all resources."
  default     = {}
}

variable "infrastructurename" {
  type        = string
  description = "The name of the infrastructure."
  default     = "artexa"
}

variable "linuxNodeSize" {
  type        = list(string)
  description = "The machine size of the Linux nodes for the regular services"
  default     = ["m5a.4xlarge", "m5a.8xlarge"]
}

variable "linuxNodeCountMin" {
  type        = number
  description = "The minimum number of Linux nodes for the regular services"
  default     = 1
}

variable "linuxNodeCountMax" {
  type        = number
  description = "The maximum number of Linux nodes for the regular services"
  default     = 12
}

variable "kubernetesVersion" {
  type        = string
  description = "The version of the EKS cluster."
  default     = "1.29"
}

variable "vpcCidr" {
  type        = string
  description = "The CIDR for the virtual private cluster."
  default     = "10.1.0.0/18"
}

variable "vpcPrivateSubnets" {
  type        = list(any)
  description = "List of CIDRs for the private subnets."
  default     = ["10.1.0.0/22", "10.1.4.0/22", "10.1.8.0/22"]
}

variable "vpcPublicSubnets" {
  type        = list(any)
  description = "List of CIDRs for the public subnets."
  default     = ["10.1.12.0/22", "10.1.16.0/22", "10.1.20.0/22"]
}

variable "artexa_instances" {
  type = map(object({
    name                         = string
    postgresqlVersion            = string
    postgresqlStorage            = number
    postgresqlMaxStorage         = number
    db_instance_type_artexa      = string
    postgresqlStorageKeycloak    = number
    postgresqlMaxStorageKeycloak = number
    db_instance_type_keycloak    = string
    secretname                   = string
    enable_deletion_protection   = bool
    enable_backup_service        = bool
    enable_irsa                  = bool
    backup_retention             = number
    enable_keycloak              = bool
    k8s_namespace                = string

  }))
  description = "A list containing the individual ARTEXA instances, such as 'staging' and 'production'."
  default = {
    "production" = {
      name                         = "production"
      postgresqlVersion            = "16"
      postgresqlStorage            = 20
      postgresqlMaxStorage         = 100
      postgresqlStorageKeycloak    = 20
      postgresqlMaxStorageKeycloak = 100
      db_instance_type_keycloak    = "db.t3.large"
      db_instance_type_artexa      = "db.t3.large"
      secretname                   = "aws-artexa-dev-production"
      enable_deletion_protection   = true
      enable_backup_service        = true
      backup_retention             = 7
      enable_irsa                  = true
      enable_keycloak              = true
      k8s_namespace                = "artexa"
    }
  }
}

variable "map_accounts" {
  type        = list(string)
  description = "Additional AWS account numbers to add to the aws-auth ConfigMap"
  default     = []
}

variable "map_roles" {
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  description = "Additional IAM roles to add to the aws-auth ConfigMap"
  default     = []
}

variable "map_users" {
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  description = "Additional IAM users to add to the aws-auth ConfigMap"
  default     = []
}

variable "vpcId" {
  type        = string
  description = "The ID of preconfigured VPC. Empty string will create a new VPC. Check the subnet requirements for nodes https://docs.aws.amazon.com/eks/latest/userguide/network-reqs.html#node-subnet-reqs. "
  default     = ""
}
variable "private_subnet_filter" {
  type = list(object({
    name   = string
    values = list(string)
  }))
  description = "Tag filter"
  default     = [{ name = "subnet-id", values = ["subnet-0490ffe38d62c4c4c"] }]
}

variable "public_subnet_filter" {
  type = list(object({
    name   = string
    values = list(string)
  }))
  description = "Tag filter"
  default     = [{ name = "subnet-id", values = ["subnet-0490ffe38d62c4c4c"] }]
}

variable "application_loadbalancer" {
  type        = bool
  description = "Deploy an AWS Application Loadbalancer"
  default     = false
}

variable "certificate_arn" {
  type        = string
  description = "TLS certificate ARN. Only required when application_loadbalancer is true."
  default     = ""
}

variable "license_server" {
  type        = bool
  description = "Specifies whether a license server VM will be created."
  default     = false
}

variable "license_server_type" {
  type        = string
  description = "EC2 Instance type of the license server."
  default     = "t3a.medium"
}

variable "codemeter" {
  type        = string
  description = "Download link for codemeter rpm package."
  default     = "https://www.wibu.com/support/user/user-software/file/download/13346.html?tx_wibudownloads_downloadlist%5BdirectDownload%5D=directDownload&tx_wibudownloads_downloadlist%5BuseAwsS3%5D=0&cHash=8dba7ab094dec6267346f04fce2a2bcd"
}


#-------------------------------
# EKS Cluster VPC Config
#-------------------------------
variable "cluster_endpoint_public_access" {
  description = "Indicates whether or not the EKS public API server endpoint is enabled. Default to EKS resource and it is true"
  type        = bool
  default     = true
}

variable "cluster_endpoint_private_access" {
  description = "Indicates whether or not the EKS private API server endpoint is enabled. Default to EKS resource and it is false"
  type        = bool
  default     = false
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_patching" {
  type        = bool
  description = "Scans license server EC2 instance and EKS nodes for updates. Installs patches on license server automatically. EKS nodes need to be updated manually."
  default     = false
}

variable "scan_schedule" {
  type        = string
  description = "6-field Cron expression describing the scan maintenance schedule. Must not overlap with variable install_schedule."
  default     = "cron(0 0 * * ? *)"
}

variable "install_schedule" {
  type        = string
  description = "6-field Cron expression describing the install maintenance schedule. Must not overlap with variable scan_schedule."
  default     = "cron(0 3 * * ? *)"
}

variable "maintainance_duration" {
  type        = number
  description = "How long in hours for the maintenance window."
  default     = 3
}
