# arn:aws:s3:::terraform-backend-state-emilesherrott

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.12"
    }
  }
  backend "s3" {
    bucket = "mybucket"       # Will be overridden from build
    key    = "path/to/my/key" # Will be overridden from build
    region = "us-east-1"
  }
}

resource "aws_default_vpc" "default" {

}

data "aws_subnets" "subnets" {
  filter {
    name = "vpc-id"
    values = [aws_default_vpc.default.id]
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}


module "lfacademy-cluster" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "lfacademy-cluster"
  cluster_version = "1.28"
  subnet_ids      = ["subnet-0caae72f8762e71fd", "subnet-0dc83f0a90e6341d2"]
  #subnet_ids = data.aws_subnet_ids.subnets.ids
  vpc_id                         = aws_default_vpc.default.id
  cluster_endpoint_public_access = true
  #vpc_id         = "vpc-1234556abcdef"
  # eks_managed_node_group_defaults = ["t2.micro"]
  eks_managed_node_groups = {
    default = {
      instance_types = ["t2.micro"]
      min_size       = 1
      max_size       = 10
      desired_size   = 1
    }
  }
}



data "aws_eks_cluster" "cluster" {
  name = module.lfacademy-cluster.id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.lfacademy-cluster.id
}



resource "kubernetes_cluster_role_binding" "example" {
  metadata {
    name = "fabric8-rbac"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = "default"
  }
}


provider "aws" {
  region  = "us-east-1"
}