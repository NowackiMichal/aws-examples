resource "aws_vpc" "my_vpc" {
  cidr_block = "172.16.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "nebo-vnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_route_table" "my_route" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_route" "outbound_route" {
  route_table_id = aws_route_table.my_route.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.gw.id
}

resource "aws_route_table_association" "subnet_association" {
  subnet_id = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.my_route.id
}

resource "aws_subnet" "my_subnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "172.16.10.0/24"
  availability_zone = "eu-central-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "nebo-subnet"
  }
 
}
# Create a new security group allowing only inbound traffic on port 80
resource "aws_security_group" "nginx_sg" {
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Launch an EC2 instance with NGINX installed
resource "aws_instance" "nginx_instance" {
  ami             = "ami-06dd92ecc74fdfb36"
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.my_subnet.id
  vpc_security_group_ids = [aws_security_group.nginx_sg.id]
  associate_public_ip_address = true  
  user_data = <<-EOF
              #!/bin/bash
              apt update
              apt install -y nginx
              echo '<html><body><h1>Cloud Solutions</h1><p>This is the CLOUD: Manage Public DNS names test page.</p></body></html>' > /var/www/html/index.nginx-debian.html 
              sudo systemctl restart nginx
              EOF
}


# Output the public IP address of the EC2 instance
output "public_ip" {
  value = aws_instance.nginx_instance.public_ip
}

# Create an A record pointing to the EC2 instance's public IP
resource "aws_route53_record" "example_record" {
  zone_id = var.existing_hosted_zone_id
  name    = "cloud-solutions.website"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.nginx_instance.public_ip]
}