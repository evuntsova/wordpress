terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.52.0"
    }
  }
}
#Provider
provider "aws" {
  # Configuration options
  region = "us-east-1"
}