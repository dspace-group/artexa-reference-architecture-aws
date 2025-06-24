
locals {
  create_vpc                      = var.vpcId == ""
  vpc_id                          = local.create_vpc ? module.vpc[0].vpc_id : var.vpcId
  private_subnet_ids              = local.create_vpc ? module.vpc[0].private_subnets : [for s in data.aws_subnet.private_subnet : s.id]
  public_subnet_ids               = local.create_vpc ? module.vpc[0].public_subnets : [for s in data.aws_subnet.public_subnet : s.id]
  vpc_cidr                        = local.create_vpc ? module.vpc[0].vpc_cidr_block : data.aws_vpc.preconfigured[0].cidr_block
  license_server                  = "${var.infrastructurename}-license-server"
  license_server_role             = "${var.infrastructurename}-license-server-role"
  license_server_policy           = "${var.infrastructurename}-license-server-policy"
  license_server_bucket_name      = "${var.infrastructurename}-license-server-bucket"
  license_server_instance_profile = "${var.infrastructurename}-license-server-instance-profile"
  patchgroupid                    = "${var.infrastructurename}-patch-group"
}
