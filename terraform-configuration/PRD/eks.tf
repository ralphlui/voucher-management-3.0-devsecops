locals {
  availability_zones = ["${var.aws_region}a", "${var.aws_region}b"]
}

# Fetch its information from other configuration
data "aws_vpc" "vpc" {
  tags = {
    Name = "my-vpc-va3.0"
  }
}

data "aws_subnets" "private_subnet_a" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }

  filter {
    name   = "tag:Name"
    values = ["my-subnet-private2-app-${local.availability_zones[0]}"]
  }
}

data "aws_subnets" "private_subnet_b" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  } 

  filter { 
    name   = "tag:Name"
    values = ["my-subnet-private2-app-${local.availability_zones[1]}"]
  }
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

# Create an EKS cluster with a managed node group
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "app-cluster-1"
  cluster_version = "1.31"

  # VPC and Subnets
  vpc_id     = data.aws_vpc.vpc.id
  subnet_ids = [data.aws_subnets.private_subnet_a.ids[0], data.aws_subnets.private_subnet_b.ids[0]]

  # Enable SSH access to worker nodes
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  enable_irsa               = true # Enable IAM Roles for Service Accounts (IRSA)

  # Managed node group
  eks_managed_node_groups = {
    linux-nodes = {
      min_size     = 2 
      max_size     = 4 
      desired_size = 2

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"

      # SSH access
      key_name = "EKS-node-keypair"

      # Node group networking
      subnet_ids = [data.aws_subnets.private_subnet_a.ids[0], data.aws_subnets.private_subnet_b.ids[0]]

      node_group_additional_security_group_ids = []
    }
  }

  # Enable public access temporarily
  cluster_endpoint_public_access  = true
  #cluster_endpoint_private_access = true
}

# Create an IAM policy for the AWS Load Balancer Controller
resource "aws_iam_policy" "aws_load_balancer_controller" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  description = "IAM policy for the AWS Load Balancer Controller"
  policy      = file("../../../../keypairs/iam_policy.json")
}

# Create an IAM role for the AWS Load Balancer Controller
resource "aws_iam_role" "aws_load_balancer_controller" {
  name = "AmazonEKSLoadBalancerControllerRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:sub" : "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })
}

# Attach the IAM policy to the IAM role
resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
  role       = aws_iam_role.aws_load_balancer_controller.name
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
}

# Create a Kubernetes ServiceAccount for the AWS Load Balancer Controller
resource "kubernetes_service_account" "aws_load_balancer_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.aws_load_balancer_controller.arn
    }
  }
}

# Create an IAM policy for Fluent Bit to write logs to CloudWatch
resource "aws_iam_policy" "fluent_bit_cloudwatch" {
  name        = "FluentBitCloudWatchPolicy"
  description = "IAM policy for Fluent Bit to write logs to CloudWatch"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

# Create a separate IAM role for Fluent Bit
resource "aws_iam_role" "fluent_bit" {
  name = "FluentBitRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:sub" : "system:serviceaccount:amazon-cloudwatch:fluent-bit"
          }
        }
      }
    ]
  })
}

# Attach the Fluent Bit IAM policy to the separate IAM role
resource "aws_iam_role_policy_attachment" "fluent_bit_cloudwatch" {
  role       = aws_iam_role.fluent_bit.name
  policy_arn = aws_iam_policy.fluent_bit_cloudwatch.arn
}

# Create the amazon-cloudwatch namespace if it doesn't exist
resource "kubernetes_namespace" "cloudwatch" {
  metadata {
    name = "amazon-cloudwatch"
  }
}

# Create a Kubernetes ServiceAccount for Fluent Bit
resource "kubernetes_service_account" "fluent_bit" {
  metadata {
    name      = "fluent-bit"
    namespace = "amazon-cloudwatch"
    annotations = {
      "eks.amazonaws.com/role-arn"               = aws_iam_role.fluent_bit.arn
      "eks.amazonaws.com/audience"               = "sts.amazonaws.com"
      "eks.amazonaws.com/sts-regional-endpoints" = "true"
      "eks.amazonaws.com/token-expiration"       = "86400"
    }
  }
}

# Deploy the AWS Load Balancer Controller using Helm
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.8.2"

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.aws_load_balancer_controller.metadata[0].name
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "vpcId"
    value = data.aws_vpc.vpc.id
  }

  depends_on = [module.eks]
}

# Deploy the NGINX Ingress Controller using Helm
resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "voucher-management-app"
  create_namespace = true

  set {
    name  = "controller.replicaCount"
    value = "2"
  }

  set {
    name  = "controller.service.type"
    value = "NodePort"
  }

  set {
    name  = "controller.service.externalTrafficPolicy"
    value = "Local"
  }

 depends_on = [module.eks] 
}
