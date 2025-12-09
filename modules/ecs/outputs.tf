# modules/ecs/outputs.tf

output "cluster_id" {
  description = "ECS Cluster ID"
  value       = aws_ecs_cluster.main.id
}

output "cluster_name" {
  description = "ECS Cluster 이름"
  value       = aws_ecs_cluster.main.name
}

output "was_service_name" {
  description = "WAS Service 이름"
  value       = aws_ecs_service.was.name
}
