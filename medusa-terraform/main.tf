provider "aws" {
  region = "us-west-2" # Specify your AWS region
}

# Create VPC
resource "aws_vpc" "ecs_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "ecs-vpc"
  }
}

# Create Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.ecs_vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.ecs_vpc.id
  tags = {
    Name = "ecs-igw"
  }
}

# Create Route Table for public access
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.ecs_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "public-route-table"
  }
}

# Associate Route Table with Public Subnet
resource "aws_route_table_association" "public_route_table_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# Create Security Group
resource "aws_security_group" "ecs_sg" {
  vpc_id = aws_vpc.ecs_vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "ecs-sg"
  }
}

# Create ECS Cluster
resource "aws_ecs_cluster" "medusa-ecs-cluster" {
  name = "medusa-ecs-cluster"
  tags = {
    Name = "medusa-ecs-cluster"
  }
}

# Create Auto Scaling Group for Spot Instances
resource "aws_launch_template" "spot_launch_template" {
  name_prefix   = "ecs-spot-template-"
  image_id      = data.aws_ami.ami.id # Use the correct AMI for your region
  instance_type = "t3.micro"          # Specify instance type

  spot_options {
    spot_instance_type = "one-time"
  }

  key_name = "swapna.pem"          # Replace with your key pair

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ecs_sg.id]
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "spot_asg" {
  desired_capacity     = 1
  max_size             = 2
  min_size             = 1
  vpc_zone_identifier  = [aws_subnet.public_subnet.id]
  launch_template {
    id      = aws_launch_template.spot_launch_template.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "ecs-spot-asg"
    propagate_at_launch = true
  }
}

# ECS Capacity Provider for Spot Instances
resource "aws_ecs_capacity_provider" "spot_capacity_provider" {
  name = "spot-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.spot_asg.arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      maximum_scaling_step_size = 1
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 10
    }
  }

  tags = {
    Name = "spot-capacity-provider"
  }
}

# Attach Capacity Provider to ECS Cluster
resource "aws_ecs_cluster_capacity_providers" "ecs_cluster_capacity_providers" {
  cluster_name       = aws_ecs_cluster.medusa-ecs-cluster.name
  capacity_providers = [aws_ecs_capacity_provider.spot_capacity_provider.name]
  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.spot_capacity_provider.name
    weight            = 1
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "medusa_task" {
  family                   = "medusa-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = "10"
  memory                   = "512"

  container_definitions = jsonencode([{
    name      = "medusa"
    image     = "medusa:latest"
    cpu       = 10
    memory    = 512
    essential = true
    portMappings = [{
      containerPort = 80
      hostPort      = 80
      protocol      = "tcp"
    }]
  }])

  tags = {
    Name = "medusa-task"
  }
}

# ECS Service using Spot Instances
resource "aws_ecs_service" "medusa_service" {
  name            = "medusa-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.medusa_task.arn
  desired_count   = 1
  launch_type     = "EC2"

  network_configuration {
    subnets         = [aws_subnet.public_subnet.id]
    security_groups = [aws_security_group.ecs_sg.id]
  }
  deployment_controller {
    type = "ECS"
  }

  tags = {
    Name = "medusa-service"
  }
}

# Data for AMI
data "aws_ami" "ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
