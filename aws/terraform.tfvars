# terraform.tfvars.example
# 실제 사용 시 terraform.tfvars로 복사하고 값을 수정하세요
# cp terraform.tfvars.example terraform.tfvars

# =================================================
# 기본 설정
# =================================================

environment = "prod"
aws_region  = "ap-northeast-2"

# =================================================
# 도메인 설정
# =================================================

# 도메인 없이 사용 (ALB URL로 직접 접속)
enable_custom_domain = false
domain_name          = ""
create_hosted_zone   = false

# 도메인 있을 때 (주석 해제하고 수정)
# enable_custom_domain = true
# domain_name          = "example.com"
# create_hosted_zone   = true

# =================================================
# DockerHub 이미지 설정
# =================================================

# cloud039/test 이미지 사용
docker_image_was = "cloud039/test:latest"
docker_image_web = "nginx:1.25-alpine"

# =================================================
# VPN 설정 (Azure 연결)
# =================================================

# Azure VPN Gateway Public IP
azure_vpn_gateway_ip = "4.218.9.99"

# Azure VNet CIDR
azure_vnet_cidr = "172.16.0.0/16"

# VPN Shared Key (AWS와 Azure에서 동일해야 함)
vpn_shared_key = "Va7fKsbnnsB5dJY4XgzDgMEzQc1YWd5L6t/8lH5txY0="

# =================================================
# 데이터베이스 설정
# =================================================

db_name     = "petclinic"
db_username = "admin"

# ⚠️ 보안 주의: 비밀번호는 환경 변수나 배포 시 입력 권장
# 방법 1: 환경 변수
# export TF_VAR_db_password="your-secure-password"
#
# 방법 2: 배포 시 입력
# terraform apply 실행 시 프롬프트에서 입력
#
# 방법 3: 여기에 직접 입력 (비추천)
# db_password = "YourSecurePassword123!"

# =================================================
# VPC 설정
# =================================================

aws_vpc_cidr = "10.0.0.0/16"

aws_availability_zones = [
  "ap-northeast-2a",
  "ap-northeast-2c"
]

# =================================================
# EKS 노드 설정
# =================================================

eks_node_instance_type = "t3.medium"

# Web Tier
eks_web_desired_size = 2
eks_web_min_size     = 1
eks_web_max_size     = 4

# WAS Tier
eks_was_desired_size = 2
eks_was_min_size     = 1
eks_was_max_size     = 4

# =================================================
# RDS 설정
# =================================================

rds_instance_class      = "db.t3.medium"
rds_allocated_storage   = 100
rds_max_allocated_storage = 200
rds_multi_az            = true
rds_backup_retention    = 7
rds_deletion_protection = true
rds_skip_final_snapshot = false

# =================================================
# DMS 설정 (데이터 복제)
# =================================================

dms_instance_class = "dms.t3.medium"
dms_allocated_storage = 100
enable_dms_replication = true

# =================================================
# 비용 관리
# =================================================

# 예산 초과 알림 받을 이메일
budget_alert_email = "your-email@example.com"

# 월 예산 한도 (USD)
monthly_budget_limit = 1000

# 비용 최적화 기능 활성화
enable_cost_optimization = true

# Slack Webhook (선택사항)
# slack_webhook_url = " "

# =================================================
# 태그 설정
# =================================================

common_tags = {
  Environment = "prod"
  Project     = "PetClinic"
  ManagedBy   = "Terraform"
  Team        = "AWS2"
  CostCenter  = "KDT-Bespin"
}
