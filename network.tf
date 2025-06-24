module "vpc" {
  count                = local.create_vpc ? 1 : 0
  source               = "terraform-aws-modules/vpc/aws"
  version              = "5.5.3"
  name                 = "${var.infrastructurename}-vpc"
  cidr                 = var.vpcCidr
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = var.vpcPrivateSubnets
  public_subnets       = var.vpcPublicSubnets
  enable_nat_gateway   = true
  create_igw           = true
  enable_dns_hostnames = true
  single_nat_gateway   = true
  tags                 = var.tags
  public_subnet_tags = {
    "kubernetes.io/cluster/${var.infrastructurename}" = "shared"
    "kubernetes.io/role/elb"                          = "1"
    "purpose"                                         = "public"
  }
  private_subnet_tags = {
    "kubernetes.io/cluster/${var.infrastructurename}" = "shared"
    "kubernetes.io/role/internal-elb"                 = "1"
    "purpose"                                         = "private"
  }
}

module "security_group" {
  source      = "terraform-aws-modules/security-group/aws"
  version     = "5.1.1"
  name        = "${var.infrastructurename}-db-sg"
  description = "PostgreSQL security group"
  vpc_id      = local.vpc_id
  tags        = var.tags
  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access from within VPC"
      cidr_blocks = local.vpc_cidr
    },
  ]
}
