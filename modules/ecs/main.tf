# modules/ecs/main.tf
# ECS Fargate 기반 Web/WAS Tier 구성

# ==================== ECS Cluster ====================

# ECS 클러스터 생성
resource "aws_ecs_cluster" "main" {
  name = "ecs-cluster-${var.environment}"
  
  # Container Insights 활성화 (모니터링)
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  
  tags = {
    Name = "ecs-cluster"
  }
}

# ECS Cluster Capacity Providers (Fargate)
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name
  
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]
  
  # 기본 전략: Fargate 사용
  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 1
  }
}

# ==================== CloudWatch Log Groups ====================

# Web Tier 로그 그룹
resource "aws_cloudwatch_log_group" "web" {
  name              = "/ecs/web-tier-${var.environment}"
  retention_in_days = 7
  
  tags = {
    Name = "web-tier-logs"
  }
}

# WAS Tier 로그 그룹
resource "aws_cloudwatch_log_group" "was" {
  name              = "/ecs/was-tier-${var.environment}"
  retention_in_days = 7
  
  tags = {
    Name = "was-tier-logs"
  }
}

# ==================== IAM Roles ====================

# ECS 태스크 실행 역할
resource "aws_iam_role" "ecs_task_execution" {
  name = "ecs-task-execution-role-${var.environment}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ==================== WAS Tier Task Definition ====================

resource "aws_ecs_task_definition" "was" {
  family                   = "was-petclinic-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  
  container_definitions = jsonencode([{
    name  = "petclinic"
    image = var.app_image
    
    portMappings = [{
      containerPort = 8080
      protocol      = "tcp"
    }]
    
    environment = [
      { name = "SPRING_PROFILES_ACTIVE", value = "mysql" },
      { name = "MYSQL_URL", value = "jdbc:mysql://${var.db_endpoint}/${var.db_name}" },
      { name = "MYSQL_USER", value = var.db_username },
      { name = "MYSQL_PASS", value = var.db_password }
    ]
    
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.was.name
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = "was"
      }
    }
    
    healthCheck = {
      command     = ["CMD-SHELL", "curl -f http://localhost:8080/actuator/health || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60
    }
    
    essential = true
  }])
}

# WAS Security Group
resource "aws_security_group" "was_task" {
  name        = "was-task-sg-${var.environment}"
  vpc_id      = var.vpc_id
  
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# WAS ECS Service
resource "aws_ecs_service" "was" {
  name            = "was-service-${var.environment}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.was.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  
  network_configuration {
    subnets         = var.private_subnets
    security_groups = [aws_security_group.was_task.id]
  }
  
  load_balancer {
    target_group_arn = var.internal_alb_tg_arn
    container_name   = "petclinic"
    container_port   = 8080
  }
}

# ==================== Data Sources ====================

data "aws_region" "current" {}

data "aws_vpc" "main" {
  id = var.vpc_id
}
