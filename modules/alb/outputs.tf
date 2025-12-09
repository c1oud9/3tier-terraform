# modules/alb/outputs.tf

# External ALB
output "external_alb_arn" {
  description = "External ALB ARN"
  value       = aws_lb.external.arn
}

output "external_alb_dns" {
  description = "External ALB DNS 이름"
  value       = aws_lb.external.dns_name
}

output "external_alb_zone_id" {
  description = "External ALB Zone ID"
  value       = aws_lb.external.zone_id
}

output "external_target_group_arn" {
  description = "External Target Group ARN"
  value       = aws_lb_target_group.external.arn
}

# Internal ALB
output "internal_alb_arn" {
  description = "Internal ALB ARN"
  value       = aws_lb.internal.arn
}

output "internal_alb_dns" {
  description = "Internal ALB DNS 이름"
  value       = aws_lb.internal.dns_name
}

output "internal_target_group_arn" {
  description = "Internal Target Group ARN"
  value       = aws_lb_target_group.internal.arn
}

# Security Groups
output "web_tier_sg_id" {
  description = "Web Tier Security Group ID"
  value       = aws_security_group.web_tier.id
}

output "was_tier_sg_id" {
  description = "WAS Tier Security Group ID"
  value       = aws_security_group.was_tier.id
}

output "external_alb_sg_id" {
  description = "External ALB Security Group ID"
  value       = aws_security_group.external_alb.id
}

output "internal_alb_sg_id" {
  description = "Internal ALB Security Group ID"
  value       = aws_security_group.internal_alb.id
}
