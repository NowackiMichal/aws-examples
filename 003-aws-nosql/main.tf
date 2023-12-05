resource "aws_vpc" "my_vpc" {
  cidr_block = "172.16.0.0/16"
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

resource "aws_security_group" "my_security_group" {
  name        = "nebo-security-group"
  description = "Allow SSH and MongoDB traffic"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 27017
    to_port     = 27017
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

resource "aws_instance" "mongo_server" {
  ami           = "ami-0d118c6e63bcb554e"
  instance_type = "t2.micro"    
  subnet_id = aws_subnet.my_subnet.id
  vpc_security_group_ids = [aws_security_group.my_security_group.id]
  associate_public_ip_address = true
  key_name = aws_key_pair.my_key.key_name
  tags = {
    Name = "nebo-task-VM"
  }
  provisioner "remote-exec" {
    inline = ["echo 'Wait until SSH is ready'"] 
 
    connection {
      type		= "ssh"
      user		= local.ssh_user
      private_key	= file(local.private_key_path)
      host		= aws_instance.mongo_server.public_ip
    }  
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ${aws_instance.mongo_server.public_ip}, --private-key ${local.private_key_path} playbook.yml"
  }
}

resource "aws_key_pair" "my_key" {
  key_name = "my_key"
  public_key = file("~/.ssh/devops.pub")
}

output "instance_ip" {
   value = aws_instance.mongo_server.public_ip
}

