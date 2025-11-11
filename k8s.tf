

module "eks" {
  source                               = "git::https://github.com/aws-ia/terraform-aws-eks-blueprints.git?ref=v4.32.1"
  cluster_version                      = var.kubernetesVersion
  cluster_name                         = var.infrastructurename
  vpc_id                               = local.vpc_id
  private_subnet_ids                   = local.private_subnet_ids
  create_eks                           = true
  map_accounts                         = var.map_accounts
  map_users                            = var.map_users
  map_roles                            = var.map_roles
  tags                                 = var.tags
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_private_access      = var.cluster_endpoint_private_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  managed_node_groups = {
    default = {
      node_group_name    = "default"
      min_size           = var.linuxNodeCountMin
      max_size           = var.linuxNodeCountMax
      desired_size       = var.linuxNodeCountMin
      subnet_ids         = local.private_subnet_ids
      instance_types     = var.linuxNodeSize
      ami_type           = "BOTTLEROCKET_x86_64"
      launch_template_os = "bottlerocket"
    }
  }
}
module "eks-addons" {
  source                               = "git::https://github.com/aws-ia/terraform-aws-eks-blueprints.git//modules/kubernetes-addons?ref=v4.32.1"
  eks_cluster_id                       = module.eks.eks_cluster_id
  enable_amazon_eks_vpc_cni            = true
  enable_amazon_eks_coredns            = true
  enable_amazon_eks_kube_proxy         = true
  enable_ingress_nginx                 = true
  enable_cluster_autoscaler            = true
  enable_amazon_eks_aws_ebs_csi_driver = true
  tags                                 = var.tags

  ingress_nginx_helm_config = {
    values = [templatefile("${path.module}/templates/nginx_values.yaml", {
      internal = var.application_loadbalancer ? "true" : "false",
      scheme   = var.application_loadbalancer ? "internal" : "internet-facing",
      vpc_cidr = local.vpc_cidr
    })]

    namespace         = "nginx",
    create_namespace  = true
    dependency_update = true
    version           = "4.12.2",
  }
  cluster_autoscaler_helm_config = {
    version = "9.52.1"
  }
}
