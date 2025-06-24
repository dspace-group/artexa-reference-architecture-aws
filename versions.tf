terraform {
  required_version = ">= 1.1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.70.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.32.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.15.0"
    }
  }
}
