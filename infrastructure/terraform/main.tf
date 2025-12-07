terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket = "url-shortener-terraform-state"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC e Networking
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "${var.project_name}-vpc"
  cidr = "10.0.0.0/16"

  azs              = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets   = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  database_subnets = ["10.0.201.0/24", "10.0.202.0/24", "10.0.203.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = false # Alta disponibilidade
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Project = var.project_name
    Environment = var.environment
  }
}

# Security Group para RDS
resource "aws_security_group" "rds" {
  name_prefix = "${var.project_name}-rds-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
    description = "PostgreSQL from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}

# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet"
  subnet_ids = module.vpc.database_subnets

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# RDS Master Instance
resource "aws_db_instance" "master" {
  identifier = "${var.project_name}-master"
  
  # Engine
  engine               = "postgres"
  engine_version       = "15.4"
  instance_class       = var.db_instance_class
  
  # Storage
  allocated_storage     = 100
  max_allocated_storage = 1000
  storage_type          = "gp3"
  storage_encrypted     = true
  
  # Credentials
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  
  # Network
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  
  # Backup
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "mon:04:00-mon:05:00"
  
  # Monitoring
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  performance_insights_enabled    = true
  monitoring_interval             = 60
  monitoring_role_arn            = aws_iam_role.rds_monitoring.arn
  
  # High Availability
  multi_az = true
  
  # Protection
  deletion_protection = true
  skip_final_snapshot = false
  final_snapshot_identifier = "${var.project_name}-master-final-snapshot"
  
  tags = {
    Name = "${var.project_name}-master-db"
    Role = "master"
  }
}

# Read Replica 1
resource "aws_db_instance" "replica_1" {
  identifier = "${var.project_name}-replica-1"
  
  replicate_source_db = aws_db_instance.master.identifier
  instance_class      = var.db_instance_class
  
  # Storage (herdado do master)
  storage_encrypted = true
  
  # Network
  publicly_accessible = false
  
  # Monitoring
  enabled_cloudwatch_logs_exports = ["postgresql"]
  performance_insights_enabled    = true
  monitoring_interval             = 60
  monitoring_role_arn            = aws_iam_role.rds_monitoring.arn
  
  # Protection
  skip_final_snapshot = true
  
  tags = {
    Name = "${var.project_name}-replica-1"
    Role = "read-replica"
  }
}

# Read Replica 2
resource "aws_db_instance" "replica_2" {
  identifier = "${var.project_name}-replica-2"
  
  replicate_source_db = aws_db_instance.master.identifier
  instance_class      = var.db_instance_class
  
  storage_encrypted = true
  publicly_accessible = false
  
  enabled_cloudwatch_logs_exports = ["postgresql"]
  performance_insights_enabled    = true
  monitoring_interval             = 60
  monitoring_role_arn            = aws_iam_role.rds_monitoring.arn
  
  skip_final_snapshot = true
  
  tags = {
    Name = "${var.project_name}-replica-2"
    Role = "read-replica"
  }
}

# Read Replica 3
resource "aws_db_instance" "replica_3" {
  identifier = "${var.project_name}-replica-3"
  
  replicate_source_db = aws_db_instance.master.identifier
  instance_class      = var.db_instance_class
  
  storage_encrypted = true
  publicly_accessible = false
  
  enabled_cloudwatch_logs_exports = ["postgresql"]
  performance_insights_enabled    = true
  monitoring_interval             = 60
  monitoring_role_arn            = aws_iam_role.rds_monitoring.arn
  
  skip_final_snapshot = true
  
  tags = {
    Name = "${var.project_name}-replica-3"
    Role = "read-replica"
  }
}

# IAM Role para Monitoring
resource "aws_iam_role" "rds_monitoring" {
  name = "${var.project_name}-rds-monitoring"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "monitoring.rds.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# ElastiCache Redis Cluster
resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.project_name}-redis-subnet"
  subnet_ids = module.vpc.private_subnets
}

resource "aws_security_group" "redis" {
  name_prefix = "${var.project_name}-redis-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "${var.project_name}-redis"
  replication_group_description = "Redis cluster for URL shortener"
  
  engine               = "redis"
  engine_version       = "7.0"
  node_type            = "cache.t3.medium"
  number_cache_clusters = 3
  
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  security_group_ids   = [aws_security_group.redis.id]
  
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  
  automatic_failover_enabled = true
  multi_az_enabled          = true
  
  snapshot_retention_limit = 5
  snapshot_window         = "03:00-05:00"
  
  tags = {
    Name = "${var.project_name}-redis"
  }
}

# Outputs
output "rds_master_endpoint" {
  value       = aws_db_instance.master.endpoint
  description = "RDS Master endpoint"
  sensitive   = true
}

output "rds_replica_endpoints" {
  value = [
    aws_db_instance.replica_1.endpoint,
    aws_db_instance.replica_2.endpoint,
    aws_db_instance.replica_3.endpoint
  ]
  description = "RDS Read Replica endpoints"
  sensitive   = true
}

output "redis_endpoint" {
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
  description = "Redis primary endpoint"
  sensitive   = true
}