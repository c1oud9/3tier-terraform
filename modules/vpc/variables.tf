# modules/vpc/variables.tf
# VPC 모듈 입력 변수

variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
}

variable "availability_zones" {
  description = "사용할 가용 영역 리스트"
  type        = list(string)
}

variable "environment" {
  description = "환경 이름 (dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "AWS 리전"
  type        = string
}

variable "enable_flow_logs" {
  description = "VPC Flow Logs 활성화 여부"
  type        = bool
  default     = true
}

variable "enable_vpc_endpoints" {
  description = "VPC Endpoints 활성화 여부"
  type        = bool
  default     = true
}
