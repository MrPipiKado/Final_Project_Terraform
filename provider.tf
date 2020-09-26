terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket = "mrpipikado"
    key = "global/s3/terraform.tfstate"
    region = "us-west-2"

    dynamodb_table = "Terraform_final_project_locks"
    encrypt = true
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-west-2"
  shared_credentials_file = "/home/user/.aws/credentials"
}