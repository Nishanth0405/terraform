#-----------------------------------------------------------------------------------------------#
#-----------------------------EKS Variables-----------------------------------------------------#
#-----------------------------------------------------------------------------------------------#

locals {
  eks_cluster_name             = "demo-${var.project_vars.company_name}"
  eks_private_key_pem          = "demo-${var.project_vars.company_name}"
  eks_alb_name                 = "DEMO${title(var.project_vars.company_name)}ALBIngressController"
  eks_alb_description          = "DEMO${title(var.project_vars.company_name)}ALBIngressController"
  eks_addition_alb_name        = "DEMO${title(var.project_vars.company_name)}AdditionALB"
  eks_addition_alb_description = "DEMO${title(var.project_vars.company_name)}AdditionALB"
  eks_alb_role_name            = "DEMO${title(var.project_vars.company_name)}ALBRole"
  eks_autoscaler_name          = "DEMO${title(var.project_vars.company_name)}Autoscaler"
  eks_autoscaler_description   = "DEMO${title(var.project_vars.company_name)}Autoscaler"
  eks_autoscaler_role_name     = "DEMO${title(var.project_vars.company_name)}AutoscalerRole"
}


#-----------------------------------------------------------------------------------------------#
#-----------------------------KeyPair Creation--------------------------------------------------#
#-----------------------------------------------------------------------------------------------#

resource "tls_private_key" "ca_eks_key_pair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}


resource "aws_key_pair" "ca_eks_key_pair" {
  key_name   = local.eks_cluster_name
  public_key = tls_private_key.ca_eks_key_pair.public_key_openssh

  provisioner "local-exec" {
    command = "echo '${tls_private_key.ca_eks_key_pair.private_key_pem}' > ./${local.eks_private_key_pem}.pem"
  }
  tags = {
    Name        = local.eks_cluster_name
    Environment = local.eks_cluster_name
  }
}

#-----------------------------------------------------------------------------------------------#
#-----------------------------EKS Creation------------------------------------------------------#
#-----------------------------------------------------------------------------------------------#

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.eks_cluster_name
  cluster_version = var.eks_vars.eks_version

  cluster_endpoint_private_access = var.cluster_endpoint_private_access
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access

  subnet_ids  = module.vpc.private_subnets
  vpc_id      = module.vpc.vpc_id
  enable_irsa = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  eks_managed_node_group_defaults = {
    disk_size = 30
  }


  eks_managed_node_groups = {
    node = {
      desired_capacity = 2
      max_capacity     = 3
      min_capacity     = 2

      # The instance size and type has to be confirmed. So the instance type is Left blank

      instance_types = ["m5.xlarge"]
      
      #instance_type = var.eks_vars.instance_type
      key_name = local.eks_cluster_name
      additional_tags = {
        Name                                                  = local.eks_cluster_name
        "k8s.io/cluster-autoscaler/${local.eks_cluster_name}" = "owned"
        "k8s.io/cluster-autoscaler/enabled"                   = "TRUE"
        Environment                                           = local.eks_cluster_name
      }
    }
  }

  # manage_aws_auth_configmap = true

  # aws_auth_roles = [
  #   {
  #     rolearn  = module.eks_terraform_admin_iam_assumable_role.iam_role_arn
  #     username = module.eks_terraform_admin_iam_assumable_role.iam_role_name
  #     groups   = ["system:masters"]
  #   },
  # ]

  #config_output_path = "./"
}

output "admin_iam_role_arn" {
  value = module.eks.cluster_iam_role_arn
}

output "cluster_name" {
  value = local.eks_cluster_name
}

#-----------------------------------------------------------------------------------------------#
#-----------------------------EKS ALB Role Creation---------------------------------------------#
#-----------------------------------------------------------------------------------------------#

resource "aws_iam_policy" "canstring_analyzer_role_alb_policy" {
  name        = local.eks_alb_name
  description = local.eks_alb_description
  policy      = file("${path.module}/policy-documents/eks-alb.json")
}


resource "aws_iam_policy" "canstring_analyzer_role_eks_addition_alb_policy" {
  name        = local.eks_addition_alb_name
  description = local.eks_addition_alb_description
  policy      = file("${path.module}/policy-documents/eks-alb-additional.json")
}



resource "aws_iam_role" "canstring_analyzer_role_alb" {
  name = local.eks_alb_role_name

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : module.eks.oidc_provider_arn
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub" : "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "canstring_analyzer_role_alb_policy_attach_policy" {
  role       = aws_iam_role.canstring_analyzer_role_alb.name
  policy_arn = aws_iam_policy.canstring_analyzer_role_alb_policy.arn
}


resource "aws_iam_role_policy_attachment" "canstring_analyzer_role_additional_alb_policy_attach_policy" {
  role       = aws_iam_role.canstring_analyzer_role_alb.name
  policy_arn = aws_iam_policy.canstring_analyzer_role_eks_addition_alb_policy.arn
}


output "Alb_iam_role_arn" {
  description = "ARN of admin IAM role"
  value       = aws_iam_role.canstring_analyzer_role_alb.arn
}

#-----------------------------------------------------------------------------------------------#
#-----------------------------EKS Autoscaler Role Creation-------------------------------------------#
#-----------------------------------------------------------------------------------------------#



resource "aws_iam_policy" "canstring_analyzer_role_eks_autoscaler_policy" {
  name        = local.eks_autoscaler_name
  description = local.eks_autoscaler_description
  policy      = file("${path.module}/policy-documents/eks-autoscaler.json")
}


resource "aws_iam_role" "canstring_analyzer_role_autoscaler" {
  name = local.eks_autoscaler_role_name

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : module.eks.oidc_provider_arn
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub" : "system:serviceaccount:kube-system:cluster-autoscaler"
          }
        }
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "canstring_analyzer_role_autoscaler_attach_policy" {
  role       = aws_iam_role.canstring_analyzer_role_autoscaler.name
  policy_arn = aws_iam_policy.canstring_analyzer_role_eks_autoscaler_policy.arn
}

output "Autoscaler_iam_role_arn" {
  value = aws_iam_role.canstring_analyzer_role_autoscaler.arn
}
#-----------------------------------------------------------------------------------------------#

 data "aws_eks_cluster" "cluster" {
     name = local.eks_cluster_name
 }

 data "aws_eks_cluster_auth" "cluster" {
     name = local.eks_cluster_name
 }

 provider "kubernetes" {
   host                   = data.aws_eks_cluster.cluster.endpoint
   cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
   token                  = data.aws_eks_cluster_auth.cluster.token
   exec {
     api_version = "client.authentication.k8s.io/v1"
     args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.id]
     command     = "aws"
   }
 }