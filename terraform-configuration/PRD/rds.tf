data "aws_subnets" "private_subnet_a_db" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }

  filter {
    name   = "tag:Name"
    values = ["my-subnet-private3-db-${local.availability_zones[0]}"]
  }
}

data "aws_subnets" "private_subnet_b_db" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }

  filter {
    name   = "tag:Name"
    values = ["my-subnet-private3-db-${local.availability_zones[1]}"]
  }
}

# Create Security Group for RDS
resource "aws_security_group" "rds_prd_sg" {
  name        = "rds-prd-security_group"
  description = "Allow database traffic"
  vpc_id      = data.aws_vpc.vpc.id

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }

  ingress {
    cidr_blocks = ["10.0.0.6/32", "10.0.160.0/27", "10.0.176.0/27"]
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
  }
}

resource "aws_db_subnet_group" "db_prd_subnet_group" {
  name        = "rds-ec2-db-prd-subnet-group"
  description = "PRD RDS DB Subnet Group"
  subnet_ids  = [data.aws_subnets.private_subnet_a_db.ids[0], data.aws_subnets.private_subnet_b_db.ids[0]]

  tags = {
    Name = "rds-ec2-db-prd-subnet-group"
  }
}

# Create RDS Instance
resource "aws_db_instance" "control_server_rds" {
  identifier           = "voucher-management-prd"
  allocated_storage    = 20 
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "8.0.40"
  instance_class       = "db.t3.medium"
  username             = "admin"
  password             = "RDS_12345_rds"
  db_subnet_group_name = aws_db_subnet_group.db_prd_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_prd_sg.id]
  skip_final_snapshot  = true
  multi_az             = false
  publicly_accessible  = false
  tags = {
    Name = "MyRDSInstance"
  }
}
