# modules/rds/variables.tf

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "db_subnets" {
  description = "DB 서브넷 ID 리스트"
  type        = list(string)
}

variable "was_tier_cidrs" {
  description = "WAS Tier CIDR 블록 리스트"
  type        = list(string)
  default     = []
}

variable "lambda_cidrs" {
  description = "Lambda CIDR 블록 리스트"
  type        = list(string)
  default     = []
}

variable "environment" {
  description = "환경 이름"
  type        = string
}

variable "db_name" {
  description = "데이터베이스 이름"
  type        = string
}

variable "db_username" {
  description = "마스터 사용자명"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "마스터 패스워드"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "DB 인스턴스 클래스"
  type        = string
  default     = "db.t3.medium"
}

variable "allocated_storage" {
  description = "초기 스토리지 크기 (GB)"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "최대 스토리지 크기 (GB, Auto Scaling)"
  type        = number
  default     = 100
}

variable "multi_az" {
  description = "Multi-AZ 배포 여부"
  type        = bool
  default     = true
}

variable "backup_retention" {
  description = "백업 보관 기간 (일)"
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "삭제 방지 활성화"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "최종 스냅샷 생략 여부"
  type        = bool
  default     = false
}

variable "create_read_replica" {
  description = "Read Replica 생성 여부"
  type        = bool
  default     = false
}

variable "alarm_actions" {
  description = "CloudWatch 알람 액션"
  type        = list(string)
  default     = []
}
