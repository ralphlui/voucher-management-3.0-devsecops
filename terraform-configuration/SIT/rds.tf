# Create Security Group for RDS
#resource "aws_security_group" "rds_sg" {
#  name        = "rds-control-server-security_group"
#  description = "Allow database traffic"
#  vpc_id      = aws_vpc.vpc.id
#
#  egress {
#    cidr_blocks = ["0.0.0.0/0"]
#    from_port   = 0
#    to_port     = 0
#    protocol    = "-1"
#  }
#
#  ingress {
#    cidr_blocks = ["10.0.0.6/32"]
#    from_port   = 3306
#    to_port     = 3306
#    protocol    = "tcp"
#  }
#}

#resource "aws_db_subnet_group" "db_control_server_subnet_group" {
#  name        = "rds-ec2-db-control-server-subnet-group"
#  description = "SIT RDS DB Subnet Group"
#  subnet_ids  = [element(aws_subnet.private_subnet_a[*].id, 2), element(aws_subnet.private_subnet_b[*].id, 2)]
#
#  tags = {
#    Name = "rds-ec2-db-control-server-subnet-group"
#  }
#}

# Create RDS Instance
#resource "aws_db_instance" "control_server_rds" {
#  identifier           = "voucher-management-sit"
#  allocated_storage    = 20 
#  storage_type         = "gp2"
#  engine               = "mysql"
#  engine_version       = "8.0.40"
#  instance_class       = "db.t3.medium"
#  username             = "admin"
#  password             = "RDS_12345"
#  db_subnet_group_name = aws_db_subnet_group.db_control_server_subnet_group.name
#  vpc_security_group_ids = [aws_security_group.rds_sg.id]
#  skip_final_snapshot  = true
#  multi_az             = false
#  publicly_accessible  = false
#  tags = {
#    Name = "MyRDSInstance"
#  }
#}
