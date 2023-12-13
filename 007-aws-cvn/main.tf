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
  subnet_id = aws_subnet.snet_public.id
  route_table_id = aws_route_table.my_route.id
}

resource "aws_subnet" "snet_public" {
  vpc_id                  = aws_vpc.vnet_nebo.id
  cidr_block             = "10.0.0.0/17"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "snet-public"
  }
}

resource "aws_subnet" "snet_private" {
  vpc_id                  = aws_vpc.vnet_nebo.id
  cidr_block             = "10.0.128.0/17"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = false
  tags = {
    Name = "snet-private"
  }
}

# Security Group for VM1 (snet-private)
resource "aws_security_group" "vm1_sg" {
  vpc_id = aws_vpc.vnet_nebo.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [aws_security_group.vm2_sg.id]
  }
}

# Security Group for VM2 (snet-public)
resource "aws_security_group" "vm2_sg" {
  vpc_id = aws_vpc.vnet_nebo.id
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

resource "aws_instance" "vm1" {
  ami             = "ami-06dd92ecc74fdfb36"
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.snet_private.id
  key_name        = aws_key_pair.my_key.key_name
  vpc_security_group_ids = [aws_security_group.vm1_sg.id] 
  tags = {
    Name = "VM1"
  }
}

resource "aws_instance" "vm2" {
  ami             = "ami-06dd92ecc74fdfb36"
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.snet_public.id
  key_name        = aws_key_pair.my_key.key_name
  vpc_security_group_ids = [aws_security_group.vm2_sg.id]
  associate_public_ip_address = true
  tags = {
    Name = "VM2"
  }

}

# Output Public IP of VM2 for accessibility
output "vm2_public_ip" {
  value = aws_instance.vm2.public_ip
}


# Key pair
resource "aws_key_pair" "my_key" {
  key_name = "my_key"
  public_key = file("~/.ssh/devops.pub")
}