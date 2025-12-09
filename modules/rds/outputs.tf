# modules/rds/outputs.tf

output "db_instance_id" {
  description = "RDS 인스턴스 ID"
  value       = aws_db_instance.main.id
}

output "db_endpoint" {
  description = "RDS 엔드포인트"
  value       = aws_db_instance.main.endpoint
}

output "db_address" {
  description = "RDS 주소 (호스트명)"
  value       = aws_db_instance.main.address
}

output "db_port" {
  description = "RDS 포트"
  value       = aws_db_instance.main.port
}

output "db_arn" {
  description = "RDS ARN"
  value       = aws_db_instance.main.arn
}

output "db_name" {
  description = "데이터베이스 이름"
  value       = aws_db_instance.main.db_name
}

output "security_group_id" {
  description = "RDS Security Group ID"
  value       = aws_security_group.rds.id
}

output "read_replica_endpoint" {
  description = "Read Replica 엔드포인트"
  value       = var.create_read_replica ? aws_db_instance.read_replica[0].endpoint : null
}
