# modules/alb/variables.tf

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnets" {
  description = "Public 서브넷 ID 리스트"
  type        = list(string)
}

variable "private_subnets" {
  description = "Private 서브넷 ID 리스트"
  type        = list(string)
}

variable "was_subnets" {
  description = "WAS Tier 서브넷 ID 리스트 (Internal ALB용)"
  type        = list(string)
}

variable "environment" {
  description = "환경 이름"
  type        = string
}
