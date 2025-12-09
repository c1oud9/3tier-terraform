# modules/rds/main.tf
# RDS MySQL 모듈 (Multi-AZ)

# DB Subnet Group 생성
resource "aws_db_subnet_group" "main" {
  name       = "db-subnet-group-${var.environment}"
  subnet_ids = var.db_subnets
  
  tags = {
    Name = "db-subnet-group"
  }
}

# RDS Security Group
resource "aws_security_group" "rds" {
  name        = "rds-sg-${var.environment}"
  description = "Security group for RDS MySQL"
  vpc_id      = var.vpc_id
  
  # WAS Tier에서만 접근 허용
  ingress {
    description = "MySQL from WAS Tier"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = var.was_tier_cidrs
  }
  
  # Lambda에서 접근 허용 (DB Sync용)
  ingress {
    description = "MySQL from Lambda"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = var.lambda_cidrs
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "rds-sg"
  }
}

# RDS Parameter Group (MySQL 8.4용)
resource "aws_db_parameter_group" "mysql" {
  name   = "mysql-params-${var.environment}"
  family = "mysql8.4"  # MySQL 8.4 패밀리로 변경
  
  # 성능 및 보안 파라미터 설정
  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }
  
  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }
  
  parameter {
    name  = "max_connections"
    value = "200"
  }
  
  parameter {
    name  = "slow_query_log"
    value = "1"
  }
  
  parameter {
    name  = "long_query_time"
    value = "2"
  }
  
  tags = {
    Name = "mysql-parameter-group"
  }
}

# RDS Option Group (MySQL 8.4용)
resource "aws_db_option_group" "mysql" {
  name                     = "mysql-options-${var.environment}"
  option_group_description = "MySQL option group"
  engine_name              = "mysql"
  major_engine_version     = "8.4"  # MySQL 8.4로 변경
  
  tags = {
    Name = "mysql-option-group"
  }
}

# RDS Instance (Multi-AZ, MySQL 8.4)
resource "aws_db_instance" "main" {
  identifier     = "rds-mysql-${var.environment}"
  engine         = "mysql"
  engine_version = "8.4.3"  # MySQL 8.4.3 버전 사용
  instance_class = var.db_instance_class
  
  # 스토리지 설정
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  
  # 데이터베이스 설정
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = 3306
  
  # Multi-AZ 설정 (고가용성)
  multi_az = var.multi_az
  
  # 네트워크 설정
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  
  # 백업 설정
  backup_retention_period = var.backup_retention
  backup_window          = "03:00-04:00"  # UTC 기준
  maintenance_window     = "mon:04:00-mon:05:00"
  
  # 파라미터 및 옵션 그룹
  parameter_group_name = aws_db_parameter_group.mysql.name
  option_group_name    = aws_db_option_group.mysql.name
  
  # 모니터링
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
  monitoring_interval             = 60
  monitoring_role_arn            = aws_iam_role.rds_monitoring.arn
  
  # 성능 인사이트
  performance_insights_enabled    = true
  performance_insights_retention_period = 7
  
  # 삭제 방지 설정
  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "rds-mysql-${var.environment}-final-snapshot"
  
  tags = {
    Name = "rds-mysql-primary"
  }
}

# RDS Monitoring Role
resource "aws_iam_role" "rds_monitoring" {
  name = "rds-monitoring-role-${var.environment}"
  
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

# ==================== CloudWatch Alarms ====================

# CPU 사용률 알람
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "rds-high-cpu-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "RDS CPU 사용률이 80%를 초과했습니다"
  alarm_actions       = var.alarm_actions
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }
}

# 연결 수 알람
resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "rds-high-connections-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "100"
  alarm_description   = "RDS 연결 수가 100개를 초과했습니다"
  alarm_actions       = var.alarm_actions
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }
}

# 스토리지 공간 알람
resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "rds-low-storage-${var.environment}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "5000000000"  # 5GB
  alarm_description   = "RDS 여유 스토리지가 5GB 미만입니다"
  alarm_actions       = var.alarm_actions
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }
}

# ==================== Read Replica (Optional) ====================

# Read Replica
resource "aws_db_instance" "read_replica" {
  count = var.create_read_replica ? 1 : 0
  
  identifier             = "rds-mysql-replica-${var.environment}"
  replicate_source_db    = aws_db_instance.main.identifier
  instance_class         = var.db_instance_class
  publicly_accessible    = false
  skip_final_snapshot    = true
  
  # 성능 인사이트
  performance_insights_enabled = true
  
  tags = {
    Name = "rds-mysql-read-replica"
    Type = "ReadReplica"
  }
}
