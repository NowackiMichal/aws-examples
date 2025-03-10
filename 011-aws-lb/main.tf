# VPC configuration
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "lb-vpc"
  }
}

# Subnets
resource "aws_subnet" "public1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "eu-central-1a"
  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone = "eu-central-1b"
  tags = {
    Name = "public-subnet-2"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-gw"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "public-rt"
  }
}

# Route Table Associations
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}

# Security Groups
resource "aws_security_group" "alb_sg" {
  name        = "alb-security-group"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id

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
    Name = "alb-sg"
  }
}

resource "aws_security_group" "instance_sg" {
  name        = "instance-security-group"
  description = "Security group for EC2 instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  ingress {
        description = "Allow ssh"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "instance-sg"
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "main-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public1.id, aws_subnet.public2.id]

  tags = {
    Name        = "main-alb"
    Environment = "production"
  }
}

# Target Group
resource "aws_lb_target_group" "main" {
  name     = "main-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
# Ensure round-robin by not enabling sticky sessions
  stickiness {
    enabled = false
    type    = "lb_cookie"
  }
  health_check {
    path                = "/index.html"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "main-tg"
  }
}

# Listener
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# EC2 Instances
resource "aws_instance" "web1" {
  ami                    = "ami-07eef52105e8a2059"  # Amazon Linux 2 AMI (update for your region)
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public1.id
  security_groups        = [aws_security_group.instance_sg.id]
  key_name =  aws_key_pair.my_key.key_name
  user_data              = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y nginx
              systemctl start nginx
              systemctl enable nginx
              echo "Hello from Instance 1" > /var/www/html/index.html
              chown www-data:www-data /var/www/html/index.html
              chmod 644 /var/www/html/index.html
              systemctl restart nginx
              EOF
  tags = {
    Name = "web-server-1"
  }
}

resource "aws_instance" "web2" {
  ami                    = "ami-07eef52105e8a2059"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public1.id
  security_groups        = [aws_security_group.instance_sg.id]
  key_name =  aws_key_pair.my_key.key_name
  user_data              = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y nginx
              systemctl start nginx
              systemctl enable nginx
              echo "Hello from Instance 2" > /var/www/html/index.html
              chown www-data:www-data /var/www/html/index.html
              chmod 644 /var/www/html/index.html
              systemctl restart nginx
              EOF
  tags = {
    Name = "web-server-2"
  }
}

resource "aws_instance" "web3" {
  ami                    = "ami-07eef52105e8a2059"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public2.id
  security_groups        = [aws_security_group.instance_sg.id]
  key_name =  aws_key_pair.my_key.key_name
  user_data              = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y nginx
              systemctl start nginx
              systemctl enable nginx
              echo "Hello from Instance 3" > /var/www/html/index.html
              chown www-data:www-data /var/www/html/index.html
              chmod 644 /var/www/html/index.html
              systemctl restart nginx
              EOF
  tags = {
    Name = "web-server-3"
  }
}

# Register targets with target group
resource "aws_lb_target_group_attachment" "web1" {
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = aws_instance.web1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "web2" {
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = aws_instance.web2.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "web3" {
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = aws_instance.web3.id
  port             = 80
}
resource "aws_key_pair" "my_key" {
  key_name = "my_key"
  public_key = file("~/.ssh/devops.pub")
}
