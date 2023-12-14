resource "aws_vpc" "vnet_nebo" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "vnet-nebo"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vnet_nebo.id
}

resource "aws_route_table" "my_route" {
  vpc_id = aws_vpc.vnet_nebo.id
}


resource "aws_route" "outbound_route" {
  route_table_id = aws_route_table.my_route.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.gw.id
}

resource "aws_route_table_association" "subnet_association" {
  subnet_id = aws_subnet.vnet_public.id
  route_table_id = aws_route_table.my_route.id
}

resource "aws_subnet" "vnet_public" {
  vpc_id                  = aws_vpc.vnet_nebo.id
  cidr_block             = "10.0.0.0/17"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "vnet-public"
  }
}

# Define Network ACL
resource "aws_network_acl" "vnet_network_acl" {
  vpc_id = aws_vpc.vnet_nebo.id
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }
  ingress {
    protocol   = "tcp"
    rule_no    = 101
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }
  egress {
    rule_no       = 100
    protocol      = -1  # All traffic
    action        = "allow"
    cidr_block    = "0.0.0.0/0"  # Allow all outbound traffic
    from_port     = 0
    to_port       = 0
  }
}
resource "aws_security_group" "vm1_sg" {
  vpc_id = aws_vpc.vnet_nebo.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
   ingress {
    from_port   = 22
    to_port     = 22
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
# Associate the Network ACL with the Subnet
resource "aws_network_acl_association" "subnet_acl_association" {
  subnet_id          = aws_subnet.vnet_public.id
  network_acl_id     = aws_network_acl.vnet_network_acl.id
}

resource "aws_instance" "vm1" {
  ami             = "ami-06dd92ecc74fdfb36"
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.vnet_public.id
  key_name        = aws_key_pair.my_key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.vm1_sg.id]
  user_data = <<-EOF
              #!/bin/bash
              sudo apt update
              sudo apt install -y nginx
              sudo echo '<html><body><h1>Configured ACL</h1><p>Configure traffic control at the Subnet Level</p></body></html>' > /var/www/html/index.nginx-debian.html 
              sudo systemctl restart nginx
              EOF
  tags = {
    Name = "VM1"
  }
}

# Output Public IP of VM2 for accessibility
output "vm1_public_ip" {
  value = aws_instance.vm1.public_ip
}


# Key pair
resource "aws_key_pair" "my_key" {
  key_name = "my_key"
  public_key = file("~/.ssh/devops.pub")
}