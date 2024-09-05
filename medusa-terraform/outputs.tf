# Output ECS Cluster ARN
output "ecs_cluster_arn" {
  value       = aws_ecs_cluster.ecs_cluster.arn
}

# Output ECS Cluster Name
output "ecs_cluster_name" {
  value       = aws_ecs_cluster.ecs_cluster.name
}

# Output ECS Service Name
output "ecs_service_name" {
  value       = aws_ecs_service.medusa_service.name
}

# Output ECS Task Definition ARN
output "ecs_task_definition_arn" {
  value       = aws_ecs_task_definition.medusa_task.arn
}

# Output Spot Auto Scaling Group Name
output "spot_asg_name" {
  value       = aws_autoscaling_group.spot_asg.name
}

# Output VPC ID
output "vpc_id" {
  value       = aws_vpc.ecs_vpc.id
}

# Output Public Subnet ID
output "public_subnet_id" {
  value       = aws_subnet.public_subnet.id
}

# Output Security Group ID
output "security_group_id" {
  value       = aws_security_group.ecs_sg.id
}


