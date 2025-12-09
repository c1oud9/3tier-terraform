# modules/vpc/outputs.tf
# VPC 모듈 출력 값

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR 블록"
  value       = aws_vpc.main.cidr_block
}

# Public Subnets
output "public_subnets" {
  description = "Public 서브넷 ID 리스트"
  value       = [aws_subnet.public_a.id, aws_subnet.public_c.id]
}

output "public_subnet_cidrs" {
  description = "Public 서브넷 CIDR 블록 리스트"
  value       = [aws_subnet.public_a.cidr_block, aws_subnet.public_c.cidr_block]
}

# Private Subnets - Web Tier
output "web_subnets" {
  description = "Web Tier 서브넷 ID 리스트"
  value       = [aws_subnet.web_a.id, aws_subnet.web_c.id]
}

# Private Subnets - WAS Tier
output "was_subnets" {
  description = "WAS Tier 서브넷 ID 리스트"
  value       = [aws_subnet.was_a.id, aws_subnet.was_c.id]
}

# Private Subnets - 통합 (ECS에서 사용)
output "private_subnets" {
  description = "모든 Private 서브넷 ID 리스트"
  value = [
    aws_subnet.web_a.id,
    aws_subnet.web_c.id,
    aws_subnet.was_a.id,
    aws_subnet.was_c.id
  ]
}

# Database Subnets
output "db_subnets" {
  description = "Database 서브넷 ID 리스트"
  value       = [aws_subnet.db_a.id, aws_subnet.db_c.id]
}

# NAT Gateway
output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = aws_nat_gateway.main.id
}

output "nat_gateway_ip" {
  description = "NAT Gateway Public IP"
  value       = aws_eip.nat.public_ip
}

# Internet Gateway
output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.main.id
}

# Route Tables
output "public_route_table_id" {
  description = "Public Route Table ID"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "Private Route Table ID"
  value       = aws_route_table.private.id
}

# VPC Endpoints
output "s3_endpoint_id" {
  description = "S3 VPC Endpoint ID"
  value       = aws_vpc_endpoint.s3.id
}

output "logs_endpoint_id" {
  description = "CloudWatch Logs VPC Endpoint ID"
  value       = aws_vpc_endpoint.logs.id
}
