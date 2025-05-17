# outputs.tf

output "vpc_id" {
  description = "The ID of the VPC"
  value       = data.aws_vpc.vpc.id
}

output "private_subnet_a_ids" {
  description = "The IDs of the private subnets"
  value       = data.aws_subnets.private_subnet_a[*].id
}

output "private_subnet_b_ids" {
  description = "The IDs of the private subnets"
  value       = data.aws_subnets.private_subnet_b[*].id
}

output "cluster_name" {
  value = module.eks.cluster_name
} 
  
output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
} 

output "cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}

output "node_group_name" {
  value = keys(module.eks.eks_managed_node_groups)[0]
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "aws_load_balancer_controller_role_arn" {
  value = aws_iam_role.aws_load_balancer_controller.arn
}

output "fluent_bit_role_arn" {
  value = aws_iam_role.fluent_bit.arn
}  
