# modules/alb/main.tf
# Application Load Balancer 모듈

# ==================== External ALB (Internet-facing) ====================

# External ALB Security Group
resource "aws_security_group" "external_alb" {
  name        = "external-alb-sg-${var.environment}"
  description = "Security group for external ALB"
  vpc_id      = var.vpc_id
  
  # HTTP 인바운드
  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # HTTPS 인바운드
  ingress {
    description = "HTTPS from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # 모든 아웃바운드 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "external-alb-sg"
  }
}

# External ALB
resource "aws_lb" "external" {
  name               = "ext-alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.external_alb.id]
  subnets            = var.public_subnets
  
  enable_deletion_protection = false
  enable_http2               = true
  enable_cross_zone_load_balancing = true
  
  tags = {
    Name = "external-alb"
  }
}

# External ALB Target Group
resource "aws_lb_target_group" "external" {
  name     = "ext-tg-${var.environment}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip"
  
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/actuator/health"
    matcher             = "200"
  }
  
  deregistration_delay = 30
  
  tags = {
    Name = "external-target-group"
  }
}

# External ALB Listener (HTTP)
resource "aws_lb_listener" "external_http" {
  load_balancer_arn = aws_lb.external.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.external.arn
  }
}

# ==================== Internal ALB ====================

# Internal ALB Security Group
resource "aws_security_group" "internal_alb" {
  name        = "internal-alb-sg-${var.environment}"
  description = "Security group for internal ALB"
  vpc_id      = var.vpc_id
  
  # Web Tier에서의 접근만 허용
  ingress {
    description     = "HTTP from Web Tier"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web_tier.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "internal-alb-sg"
  }
}

# Web Tier Security Group (External ALB → Web)
resource "aws_security_group" "web_tier" {
  name        = "web-tier-sg-${var.environment}"
  description = "Security group for Web tier"
  vpc_id      = var.vpc_id
  
  # External ALB에서의 접근 허용
  ingress {
    description     = "HTTP from External ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.external_alb.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "web-tier-sg"
  }
}

# Internal ALB - WAS Tier 서브넷 사용 (각 가용영역 A, C에 하나씩)
resource "aws_lb" "internal" {
  name               = "int-alb-${var.environment}"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.internal_alb.id]
  subnets            = var.was_subnets  # WAS 서브넷 사용 (was_a: AZ-A, was_c: AZ-C)
  
  enable_deletion_protection = false
  enable_http2               = true
  
  tags = {
    Name = "internal-alb"
  }
}

# Internal ALB Target Group
resource "aws_lb_target_group" "internal" {
  name     = "int-tg-${var.environment}"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip"
  
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/actuator/health"
    matcher             = "200"
  }
  
  deregistration_delay = 30
  
  tags = {
    Name = "internal-target-group"
  }
}

# Internal ALB Listener
resource "aws_lb_listener" "internal_http" {
  load_balancer_arn = aws_lb.internal.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal.arn
  }
}

# ==================== WAS Tier Security Group ====================

# WAS Tier Security Group (Internal ALB → WAS)
resource "aws_security_group" "was_tier" {
  name        = "was-tier-sg-${var.environment}"
  description = "Security group for WAS tier"
  vpc_id      = var.vpc_id
  
  # Internal ALB에서의 접근 허용
  ingress {
    description     = "HTTP from Internal ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.internal_alb.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "was-tier-sg"
  }
}