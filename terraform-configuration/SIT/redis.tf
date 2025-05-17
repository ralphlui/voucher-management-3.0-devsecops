# Create a subnet group for the ElastiCache Redis instance
resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "redis-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_a[1].id, aws_subnet.private_subnet_b[1].id]
}

# Define the KMS key policy
data "aws_iam_policy_document" "elasticache_kms_policy" {
  statement {
    sid       = "Allow S3/root user to use the key"
    effect    = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::891377130731:root"]
    }
    actions = [
      "kms:*"
    ]
    resources = ["*"]
  }

  statement {
    sid       = "Allow S3 user to use the key"
    effect    = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::891377130731:user/S3"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
    ]
    resources = ["*"]
  }

  statement {
    sid       = "Allow ElastiCache service to use the key"
    effect    = "Allow"
    principals {
      type        = "Service"
      identifiers = ["elasticache.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey*"
    ]
    resources = ["*"]
  }
}

# Create a custom KMS key
#resource "aws_kms_key" "elasticache_kms_key" {
#  description             = "Custom KMS key for ElastiCache Serverless Redis"
#  deletion_window_in_days = 30 
#  enable_key_rotation     = true
#  policy                  = data.aws_iam_policy_document.elasticache_kms_policy.json
#
#  tags = {
#    Name        = "elasticache-kms-key"
#    Environment = "Staging/Production"
#    Project     = "Voucher Management 3.0"
#  }
#}

# Create the ElastiCache Serverless Redis instance
#resource "aws_elasticache_serverless_cache" "redis_serverless" {
#  name                  = "my-redis-cache-01"
#  engine                = "redis"
#  major_engine_version  = "7"
#  security_group_ids    = [aws_security_group.redis-cache.id]
#  subnet_ids            = aws_elasticache_subnet_group.redis_subnet_group.subnet_ids
#
#  kms_key_id = aws_kms_key.elasticache_kms_key.arn
#
#  # Optional: Add tags
#  tags = {
#    Environment = "Staging/Production"
#    Project     = "Voucher Management 3.0"
#  }
#}

#resource "aws_elasticache_replication_group" "redis_ha" {
#  replication_group_id      = "redis-cache-01"
#  description               = "Highly available Redis cluster"
#  engine                    = "redis"
#  node_type                 = "cache.t4g.micro"
#  engine_version            = "7.1"
#  parameter_group_name      = "default.redis7.cluster.on"
#  subnet_group_name         = aws_elasticache_subnet_group.redis_subnet_group.name
#  security_group_ids        = [aws_security_group.redis-cache.id]
#
#  cluster_mode              = "enabled"
#  num_node_groups           = 1
#  replicas_per_node_group   = 0
#
# automatic_failover_enabled = true
#  at_rest_encryption_enabled = true
#  transit_encryption_enabled = true
#  transit_encryption_mode    = "required"
#  snapshot_retention_limit   = 0
#  kms_key_id                = aws_kms_key.elasticache_kms_key.arn
#
#  # Tags for organizational purposes
#  tags = {
#    Environment = "Production"
#    Project     = "Voucher Management 3.0"
#  }
#}
