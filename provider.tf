terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
provider "aws" {
  region = var.region
  # this will tag all aws related resources created by terraform with this tag (this tag is required for aws ccm)
  default_tags {
    tags = {
      "kubernetes.io/cluster/kubernetes" = "owned"
    }
  }
}