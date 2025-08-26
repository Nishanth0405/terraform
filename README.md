# Terraform Scripts

This repository contains Terraform scripts used to provision cloud resources in AWS for the assignment.

## Prerequisites
- [Terraform](https://developer.hashicorp.com/terraform/downloads) v1.3+
- AWS CLI installed and configured with valid credentials
- Access to an active AWS account

## Resources Created
- Two resources as part of the assignment (ie. EKS with VPC)

## Usage

### 1. Clone the repository
```bash
git clone <repo_url>
cd demo-script

### 2. To Create the Resources
```bash
terraform init
terraform plan
terraform apply -auto-approve

### 2. To destroy the Resources
```bash
terraform destroy -auto-approve

