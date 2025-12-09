# modules/vpc/aws_vpc.tf
# AWS VPC 및 서브넷 구성 모듈

# VPC 생성
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name        = "vpc-${var.environment}"
    Environment = var.environment
  }
}

# Internet Gateway 생성
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "igw-${var.environment}"
  }
}

# ==================== Public Subnets ====================

# Public Subnet (AZ-A)
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 1)  # 10.0.1.0/24
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "public-subnet-a-${var.environment}"
    Tier = "Public"
  }
}

# Public Subnet (AZ-C)
resource "aws_subnet" "public_c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 2)  # 10.0.2.0/24
  availability_zone       = var.availability_zones[1]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "public-subnet-c-${var.environment}"
    Tier = "Public"
  }
}

# ==================== NAT Gateway ====================

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
  
  tags = {
    Name = "nat-eip-${var.environment}"
  }
  
  depends_on = [aws_internet_gateway.main]
}

# NAT Gateway (Public Subnet에 위치)
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id
  
  tags = {
    Name = "nat-gw-${var.environment}"
  }
  
  depends_on = [aws_internet_gateway.main]
}

# ==================== Private Subnets - Web Tier ====================

# Web Tier Subnet (AZ-A)
resource "aws_subnet" "web_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 11)  # 10.0.11.0/24
  availability_zone = var.availability_zones[0]
  
  tags = {
    Name = "web-subnet-a-${var.environment}"
    Tier = "Web"
  }
}

# Web Tier Subnet (AZ-C)
resource "aws_subnet" "web_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 12)  # 10.0.12.0/24
  availability_zone = var.availability_zones[1]
  
  tags = {
    Name = "web-subnet-c-${var.environment}"
    Tier = "Web"
  }
}

# ==================== Private Subnets - WAS Tier ====================

# WAS Tier Subnet (AZ-A)
resource "aws_subnet" "was_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 21)  # 10.0.21.0/24
  availability_zone = var.availability_zones[0]
  
  tags = {
    Name = "was-subnet-a-${var.environment}"
    Tier = "WAS"
  }
}

# WAS Tier Subnet (AZ-C)
resource "aws_subnet" "was_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 22)  # 10.0.22.0/24
  availability_zone = var.availability_zones[1]
  
  tags = {
    Name = "was-subnet-c-${var.environment}"
    Tier = "WAS"
  }
}

# ==================== Private Subnets - Database Tier ====================

# DB Tier Subnet (AZ-A)
resource "aws_subnet" "db_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 31)  # 10.0.31.0/24
  availability_zone = var.availability_zones[0]
  
  tags = {
    Name = "db-subnet-a-${var.environment}"
    Tier = "Database"
  }
}

# DB Tier Subnet (AZ-C)
resource "aws_subnet" "db_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 32)  # 10.0.32.0/24
  availability_zone = var.availability_zones[1]
  
  tags = {
    Name = "db-subnet-c-${var.environment}"
    Tier = "Database"
  }
}

# ==================== Route Tables ====================

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = {
    Name = "public-rt-${var.environment}"
  }
}

# Private Route Table (NAT Gateway 사용)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
  
  tags = {
    Name = "private-rt-${var.environment}"
  }
}

# ==================== Route Table Associations ====================

# Public Subnet Associations
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_c" {
  subnet_id      = aws_subnet.public_c.id
  route_table_id = aws_route_table.public.id
}

# Web Tier Associations
resource "aws_route_table_association" "web_a" {
  subnet_id      = aws_subnet.web_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "web_c" {
  subnet_id      = aws_subnet.web_c.id
  route_table_id = aws_route_table.private.id
}

# WAS Tier Associations
resource "aws_route_table_association" "was_a" {
  subnet_id      = aws_subnet.was_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "was_c" {
  subnet_id      = aws_subnet.was_c.id
  route_table_id = aws_route_table.private.id
}

# DB Tier Associations
resource "aws_route_table_association" "db_a" {
  subnet_id      = aws_subnet.db_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "db_c" {
  subnet_id      = aws_subnet.db_c.id
  route_table_id = aws_route_table.private.id
}

# ==================== VPC Endpoints (비용 절감) ====================

# S3 VPC Endpoint (Gateway Type - 무료)
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.region}.s3"
  
  route_table_ids = [
    aws_route_table.private.id
  ]
  
  tags = {
    Name = "s3-endpoint-${var.environment}"
  }
}

# CloudWatch Logs VPC Endpoint
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  subnet_ids          = [aws_subnet.web_a.id, aws_subnet.web_c.id]
  private_dns_enabled = true
  
  tags = {
    Name = "logs-endpoint-${var.environment}"
  }
}

# VPC Endpoint Security Group
resource "aws_security_group" "vpc_endpoints" {
  name        = "vpc-endpoints-sg-${var.environment}"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  
  tags = {
    Name = "vpc-endpoints-sg"
  }
}

# ==================== Network ACLs (추가 보안 계층) ====================

# Public Subnet NACL
resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.public_a.id, aws_subnet.public_c.id]
  
  # HTTP 인바운드 허용
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }
  
  # HTTPS 인바운드 허용
  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }
  
  # Ephemeral Ports 인바운드 허용
  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }
  
  # 모든 아웃바운드 허용
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  
  tags = {
    Name = "public-nacl-${var.environment}"
  }
}

# ==================== Flow Logs (네트워크 모니터링) ====================

# CloudWatch Log Group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/flowlogs-${var.environment}"
  retention_in_days = 7
  
  tags = {
    Name = "vpc-flow-logs"
  }
}

# IAM Role for VPC Flow Logs
resource "aws_iam_role" "vpc_flow_logs" {
  name = "vpc-flow-logs-role-${var.environment}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
    }]
  })
}

# IAM Policy for VPC Flow Logs
resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = "vpc-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Resource = "*"
    }]
  })
}

# VPC Flow Logs 활성화
resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.vpc_flow_logs.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
  
  tags = {
    Name = "vpc-flow-log-${var.environment}"
  }
}
