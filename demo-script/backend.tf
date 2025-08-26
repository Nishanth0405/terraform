terraform {
  backend "s3" {
    bucket         = "terraform-nish-demo" 
    key            = "demo/terraform.tfstate"        
    region         = "ap-south-1"                              
    encrypt        = true                           
  }
}