# modules/ecs/variables.tf

variable "environment" {
  description = "환경 이름"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnets" {
  description = "Private 서브넷 ID 리스트"
  type        = list(string)
}

variable "external_alb_tg_arn" {
  description = "External ALB Target Group ARN"
  type        = string
}

variable "internal_alb_tg_arn" {
  description = "Internal ALB Target Group ARN"
  type        = string
}

variable "app_image" {
  description = "애플리케이션 Docker 이미지"
  type        = string
  default     = "public.ecr.aws/docker/library/amazoncorretto:21"
}

variable "db_endpoint" {
  description = "RDS 엔드포인트"
  type        = string
}

variable "db_name" {
  description = "데이터베이스 이름"
  type        = string
}

variable "db_username" {
  description = "DB 사용자명"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "DB 패스워드"
  type        = string
  sensitive   = true
}
