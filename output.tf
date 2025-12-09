# ==================== AWS Outputs ====================

output "aws_vpc_id" {
  description = "AWS VPC ID"
  value       = module.aws_vpc.vpc_id
}

output "aws_external_alb_dns" {
  description = "AWS External ALB DNS 이름"
  value       = module.aws_alb.external_alb_dns
}

output "aws_rds_endpoint" {
  description = "AWS RDS 엔드포인트"
  value       = module.aws_rds.db_endpoint
  sensitive   = true
}

output "aws_rds_port" {
  description = "AWS RDS 포트"
  value       = module.aws_rds.db_port
}

# ==================== Azure Outputs - 비활성화 ====================

# output "azure_resource_group" {
#   description = "Azure 리소스 그룹 이름"
#   value       = azurerm_resource_group.dr.name
# }

# output "azure_vnet_id" {
#   description = "Azure VNet ID"
#   value       = module.azure_vnet.vnet_id
# }

# output "azure_aks_cluster_name" {
#   description = "Azure AKS 클러스터 이름"
#   value       = module.azure_aks.cluster_name
# }

# output "azure_aks_fqdn" {
#   description = "Azure AKS 클러스터 FQDN"
#   value       = module.azure_aks.cluster_fqdn
# }

# output "azure_mysql_fqdn" {
#   description = "Azure MySQL FQDN"
#   value       = module.azure_mysql.mysql_fqdn
#   sensitive   = true
# }

# output "azure_app_gateway_ip" {
#   description = "Azure Application Gateway 공인 IP"
#   value       = module.azure_aks.app_gateway_public_ip
# }

# ==================== VPN Outputs - 비활성화 ====================

# output "vpn_connection_status" {
#   description = "VPN 연결 상태"
#   value       = module.vpn.connection_status
# }

# output "aws_vpn_gateway_id" {
#   description = "AWS VPN Gateway ID"
#   value       = module.vpn.aws_vpn_gateway_id
# }

# output "azure_vpn_gateway_id" {
#   description = "Azure VPN Gateway ID"
#   value       = module.vpn.azure_vpn_gateway_id
# }

# ==================== Route53 Outputs ====================

output "route53_zone_id" {
  description = "Route53 Hosted Zone ID"
  value       = aws_route53_zone.main.zone_id
}

output "route53_nameservers" {
  description = "Route53 네임서버 목록"
  value       = aws_route53_zone.main.name_servers
}

output "primary_endpoint" {
  description = "Primary 엔드포인트 (AWS)"
  value       = "http://${var.domain_name}"
}

# output "secondary_endpoint" {
#   description = "Secondary 엔드포인트 (Azure)"
#   value       = "http://${module.azure_aks.app_gateway_public_ip}"
# }

# ==================== 데이터베이스 자격증명 ====================

output "db_credentials" {
  description = "데이터베이스 접속 정보"
  value = {
    username = var.db_username
    password = random_password.db_password.result
    database = var.db_name
  }
  sensitive = true
}

# ==================== S3 Backup Outputs ====================

output "backup_s3_bucket" {
  description = "백업용 S3 버킷 이름"
  value       = aws_s3_bucket.backup.id
}

output "backup_s3_arn" {
  description = "백업용 S3 버킷 ARN"
  value       = aws_s3_bucket.backup.arn
}

# ==================== Lambda Outputs ====================

output "lambda_function_name" {
  description = "DB 동기화 Lambda 함수 이름"
  value       = aws_lambda_function.db_sync.function_name
}

output "lambda_function_arn" {
  description = "DB 동기화 Lambda 함수 ARN"
  value       = aws_lambda_function.db_sync.arn
}

# ==================== CloudWatch Dashboard ====================

output "cloudwatch_dashboard_url" {
  description = "CloudWatch 대시보드 URL"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

# ==================== AKS 접속 명령어 - 비활성화 ====================

# output "aks_get_credentials_command" {
#   description = "AKS 클러스터 자격증명 가져오기 명령어"
#   value       = "az aks get-credentials --resource-group ${azurerm_resource_group.dr.name} --name ${module.azure_aks.cluster_name}"
# }

# ==================== 배포 완료 메시지 ====================

output "deployment_summary" {
  description = "배포 완료 요약"
  sensitive   = true  # DB 엔드포인트 등 민감한 정보 포함
  value = <<-EOT
  
  ╔════════════════════════════════════════════════════════════════╗
  ║         AWS 인프라 배포 완료!                                   ║
  ║         (Azure DR 사이트는 비활성화됨)                          ║
  ╚════════════════════════════════════════════════════════════════╝
  
  🌐 Primary Site (AWS):
     - Region: ${var.aws_region}
     - ALB: ${module.aws_alb.external_alb_dns}
     - RDS: ${module.aws_rds.db_endpoint}
  
  📊 Monitoring:
     - Dashboard: CloudWatch (${var.aws_region})
  
  💾 Backup:
     - S3 Bucket: ${aws_s3_bucket.backup.id}
     - Lambda Sync: 5분 주기 자동 실행
  
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  📝 다음 단계:
  
  1. Route53 네임서버 설정:
     도메인 등록업체에서 다음 네임서버로 설정하세요:
     ${join("\n     ", aws_route53_zone.main.name_servers)}
  
  2. EKS 클러스터 접속:
     aws eks update-kubeconfig --region ${var.aws_region} --name eks-${var.environment}
  
  3. 애플리케이션 배포:
     kubectl apply -f k8s-manifests/
  
  4. 데이터베이스 자격증명:
     Username: ${var.db_username}
     Password: (terraform output -raw 명령어로 확인)
     terraform output -json db_credentials
  
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  ⚠️  참고: Azure DR 사이트를 활성화하려면 main.tf의 주석을 해제하세요.
  
  EOT
}
