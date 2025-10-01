terraform {
  required_version = ">= 1.5"
  required_providers {
    aembit = {
      source  = "aembit/aembit"
      version = "~> 1.23.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0"
    }
  }
}