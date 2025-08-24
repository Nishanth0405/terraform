#-----------------------------------------------------------------------------------------------#
#-----------------------------IAM Variables-----------------------------------------------------#
#-----------------------------------------------------------------------------------------------#

locals {
  eks_user_name  = "demo-${var.project_vars.company_name}-eks-access"
  users_tags_env = "demo-${var.project_vars.company_name}"

}


#-----------------------------------------------------------------------------------------------#
#-----------------------------IAM User Creation for EKS Access----------------------------------#
#-----------------------------------------------------------------------------------------------#

resource "aws_iam_user" "demo_user_eks" {
  name = local.eks_user_name
  tags = {
    Name        = local.eks_user_name
    Environment = local.users_tags_env
  }
}

resource "aws_iam_access_key" "demo_user_eks" {
  user = aws_iam_user.demo_user_eks.name
}


output "demo_eks_access_key_id" {
  value     = aws_iam_access_key.demo_user_eks.id
  sensitive = true
}
output "demo_eks_access_secret_key" {
  value     = aws_iam_access_key.demo_user_eks.secret
  sensitive = true

}

##Create the "allow-demo-eks-terraform-admin" IAM policy with the "eks:DescribeCluster" action is to grant the necessary permissions for managing an Amazon EKS cluster##

module "iam_policy_eks_admin_access" {
  source        = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version       = "5.22.0"
  name          = "allow-demo-eks-terraform-admin"
  create_policy = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "eks:DescribeCluster",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

#### Creating an IAM role called "demo-eks-terraform-admin" and associating it with the Kubernetes 'system:masters' Role-Based Access Control (RBAC) group. ####

module "eks_terraform_admin_iam_assumable_role" {
  source                  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version                 = "5.22.0"
  role_name               = "demo-eks-terraform-admin"
  create_role             = true
  role_requires_mfa       = false
  custom_role_policy_arns = [module.iam_policy_eks_admin_access.arn]
  trusted_role_arns = [
    "arn:aws:iam::${module.vpc.vpc_owner_id}:root"
  ]
}

### IAM role is ready, create a user IAM user (demo-eks-terraform-user) that gets access to that role ###

module "iam_eks_terraform_user" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-user"
  version                       = "5.22.0"
  name                          = "demo-eks-terraform-user"
  create_iam_access_key         = false
  create_iam_user_login_profile = false
  force_destroy                 = true
}

##### IAM policy to allow assume demo-eks-terraform-admin IAM role ###

module "iam_policy_assume_eks_admin_access" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.22.0"

  name          = "allow-assume-role-demo-eks-terraform-admin"
  create_policy = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
        ]
        Effect   = "Allow"
        Resource = module.eks_terraform_admin_iam_assumable_role.iam_role_arn
      },
    ]
  })
}

#####Create an IAM group with the previously defined policy and add a user (demo-eks-terraform-user) to this group

module "eks_admins_iam_group" {
  source                            = "terraform-aws-modules/iam/aws//modules/iam-group-with-policies"
  version                           = "5.22.0"
  name                              = "demo-eks-terraform-admin"
  attach_iam_self_management_policy = false
  create_group                      = true
  group_users                       = [module.iam_eks_terraform_user.iam_user_name]
  custom_group_policy_arns          = [module.iam_policy_assume_eks_admin_access.arn]
}