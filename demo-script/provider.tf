terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      # version = ">= 5.95.0"
      version = "<6.0.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.0.2"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.19.0"
    }
  }
  required_version = ">= 0.13"
}
provider "aws" {
  region                   = var.project_vars.region
  shared_credentials_files = ["~/.aws/credentials"]
  shared_config_files      = ["~/.aws/config"]
  profile                  = var.project_vars.aws_profile
}