variable "project_vars" {
  default = {
    company_name = "test"
    region       = "us-east-2"
    aws_profile  = "default"
    account_id   = ""
  }
}


variable "eks_vars" {
  default = {
    eks_version   = "1.33"
    instance_type = "m5.xlarge"
    cidr_blocks   = []
    from_port     = 2049
    to_port       = 2049
  }
}


variable "vpc_vars" {
  default = {
    cidr            = "10.17.0.0/16"
    private_subnets = ["10.17.1.0/24", "10.17.2.0/24"]
    public_subnets  = ["10.17.3.0/24", "10.17.4.0/24"]
  }
}

variable "cluster_endpoint_private_access" {
  type        = bool
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled"
  default     = "true"
}
variable "cluster_endpoint_public_access" {
  type        = bool
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled"
  default     = "true"
}