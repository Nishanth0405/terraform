#-----------------------------------------------------------------------------------------------#
#-----------------------------VPC Variables-----------------------------------------------------#
#-----------------------------------------------------------------------------------------------#
locals {
  vpc_name                = "demo-${var.project_vars.company_name}"
  vpc_tags_env            = "demo-${var.project_vars.company_name}"
  vpc_public_subnet_name  = "demo-${var.project_vars.company_name}-public-subnet"
  vpc_private_subnet_name = "demo-${var.project_vars.company_name}-private-subnet"
}

#-----------------------------------------------------------------------------------------------#
#-----------------------------VPC Creation------------------------------------------------------#
#-----------------------------------------------------------------------------------------------#


data "aws_availability_zones" "available" {
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name                 = local.vpc_name
  cidr                 = var.vpc_vars.cidr
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = var.vpc_vars.private_subnets
  public_subnets       = var.vpc_vars.public_subnets
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_vpn_gateway   = true
  enable_dns_support   = true

  public_subnet_tags = {
    Name                                      = local.vpc_public_subnet_name
    "kubernetes.io/cluster/${local.vpc_name}" = "shared"
    "kubernetes.io/role/elb"                  = "1"
    Environment                               = local.vpc_tags_env
  }

  private_subnet_tags = {
    Name                                      = local.vpc_private_subnet_name
    "kubernetes.io/cluster/${local.vpc_name}" = "shared"
    "kubernetes.io/role/internal-elb"         = "1"
    Environment                               = local.vpc_tags_env
  }
}