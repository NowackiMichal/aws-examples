# -------------------- VPC --------------------
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Public Subnet (For NAT Gateway)
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-central-1a"
}

# Private Subnet (For ECS)
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-central-1a"
}

# -------------------- Internet Gateway & NAT --------------------
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_1.id
}

# Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main_igw.id
}

resource "aws_route_table_association" "public_subnet_assoc" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
}

# Private Route Table (Uses NAT Gateway)
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main_vpc.id
}

resource "aws_route" "nat_gateway_route" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
}

resource "aws_route_table_association" "private_subnet_assoc" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_rt.id
}

# -------------------- Security Group --------------------
resource "aws_security_group" "ecs_sg" {
  vpc_id = aws_vpc.main_vpc.id

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
}

# -------------------- AWS Secrets Manager --------------------
resource "aws_secretsmanager_secret" "my_secret" {
  name = "MY_SECRET"
}

resource "aws_secretsmanager_secret_version" "my_secret_value" {
  secret_id     = aws_secretsmanager_secret.my_secret.id
  secret_string = jsonencode({ API_KEY = "XXXX-XXXX" })
}

# -------------------- ECS Cluster --------------------
resource "aws_ecs_cluster" "my_cluster" {
  name = "nginx-cluster"
}

resource "aws_ecs_task_definition" "nginx_task" {
  family                   = "nginx-task"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_execution_role.arn 
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name  = "nginx"
      image = "nginx:latest"
      essential = true
      portMappings = [{
        containerPort = 80
        hostPort      = 80
      }]
      secrets = [
        {
          name = "API_KEY"
          valueFrom = aws_secretsmanager_secret.my_secret.arn
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/aws/ecs/nginx"
          awslogs-region        = "eu-central-1"
          awslogs-stream-prefix = "nginx"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "nginx_service" {
  name            = "nginx-service"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.nginx_task.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  enable_execute_command = true 
  network_configuration {
    subnets          = [aws_subnet.private_1.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false  # Uses NAT Gateway for internet access
  }
}
# 5. Create Auto Scaling for ECS
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 5
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.my_cluster.name}/${aws_ecs_service.nginx_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_scale_up" {
  name               = "ecs-scale-up"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 30.0 # low value for testing purposes
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}
# -------------------- CloudWatch Log Group --------------------
resource "aws_cloudwatch_log_group" "ecs_nginx_logs" {
  name              = "/aws/ecs/nginx"
  retention_in_days = 7
}

# -------------------- IAM Role for ECS --------------------
resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}
resource "aws_iam_policy" "secrets_manager_policy" {
  name        = "SecretsManagerAccess"
  description = "Allows ECS tasks to access Secrets Manager"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_secrets_attachment" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.secrets_manager_policy.arn
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_ecr_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy" "ecs_exec_policy" {
    name = "ecsExecPolicy"
    role = aws_iam_role.ecs_execution_role.id
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = [
                    "ssmmessages:CreateControlChannel",
                    "ssmmessages:CreateDataChannel",
                    "ssmmessages:OpenControlChannel",
                    "ssmmessages:OpenDataChannel"
                ]
                Resource = "*"
            }
        ]
    })
  
}

resource "aws_iam_policy" "secrets_access_policy" {
  name        = "SecretsAccessPolicy"
  description = "Allow ECS to access Secrets Manager"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:ListSecrets"
        ]
        Resource = aws_secretsmanager_secret.my_secret.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_secrets_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.secrets_access_policy.arn
}