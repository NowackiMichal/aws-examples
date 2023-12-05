data "aws_availability_zones" "available_zones" {
    state = "available"
}

resource "aws_vpc" "vpc" {
    cidr_block = var.vpc_cidr_block
    enable_dns_hostnames = true
    tags = {
        Name = "nebo-vnet"
    }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.vpc.id
    tags = {
        Name = "nebo-igw"
    }
}

resource "aws_subnet" "public_subnet" {
    count = var.subnet_count.public
    vpc_id = aws_vpc.vpc.id
    cidr_block = var.public_subnet_cidr_blocks[count.index]
    availability_zone = data.aws_availability_zones.available_zones.names[count.index]
    tags = {
        Name = "nebo-vnet-public-subnet-${count.index}"
    }
}

resource "aws_subnet" "private_subnet" {
    count = var.subnet_count.private
    vpc_id = aws_vpc.vpc.id
    cidr_block = var.private_subnet_cidr_blocks[count.index]
    availability_zone = data.aws_availability_zones.available_zones.names[count.index]
    tags = {
        Name = "nebo-vnet-private-subnet-${count.index}"
    }
}

resource "aws_route_table" "public_route" {
    vpc_id = aws_vpc.vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
}

resource "aws_route_table_association" "public_rta" {
    count = var.subnet_count.public
    route_table_id = aws_route_table.public_route.id
    subnet_id = aws_subnet.public_subnet[count.index].id
}

resource "aws_route_table" "private_route" {
    vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table_association" "private_rta" {
    count = var.subnet_count.private
    route_table_id = aws_route_table.private_route.id
    subnet_id = aws_subnet.private_subnet[count.index].id
}

resource "aws_security_group" "ec2_sg" {
    name = "nebo-task-ec2-sg"
    description = "Security group for ec2"
    vpc_id = aws_vpc.vpc.id
    ingress {
        description = "Allow ssh"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        description = "Allow all outbound"
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0"]
    }
    tags = {
        Name = "nebo-task-ec2-sg"
    }
}

resource "aws_security_group" "db_sg" {
    name = "nebo-task-db-sg"
    description = "Security group for db"
    vpc_id = aws_vpc.vpc.id
    ingress {
        description = "Allow MySQL from public ec2"
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        security_groups = [ aws_security_group.ec2_sg.id ]
    }
    tags = {
        Name = "nebo-task-db-sg"
    }
}

resource "aws_db_subnet_group" "db_subnet_group" {
    name = "nebo-task-db-subnet-group"
    description = "Database subnet group for private RDS in multiple subnets"
    subnet_ids = [ for subnet in aws_subnet.private_subnet : subnet.id ]
}

resource "aws_db_instance" "db" {
    identifier = var.instance_settings.database.identifier
    allocated_storage = var.instance_settings.database.allocated_storage
    engine = var.instance_settings.database.engine
    engine_version = var.instance_settings.database.engine_version
    instance_class = var.instance_settings.database.instance_class
    db_name = var.instance_settings.database.name
    username = var.db_user
    password = var.db_password
    db_subnet_group_name = aws_db_subnet_group.db_subnet_group.id
    vpc_security_group_ids = [ aws_security_group.db_sg.id ]
    skip_final_snapshot = var.instance_settings.database.skip_final_snapshot
    deletion_protection = var.instance_settings.database.deletion_protection
}

resource "aws_instance" "ec2_instance" {
    count = var.instance_settings.instance.count
    ami = var.instance_settings.instance.ami
    instance_type = var.instance_settings.instance.instance_type
    subnet_id = aws_subnet.public_subnet[count.index].id
    key_name =  aws_key_pair.my_key.key_name
    vpc_security_group_ids = [ aws_security_group.ec2_sg.id ]
    tags = {
        Name = "nebo-task-ec2-${count.index}"
    }
}

resource "aws_eip" "ec2_eip" {
    count = var.instance_settings.instance.count
    instance = aws_instance.ec2_instance[count.index].id
    tags = {
        Name = "nebo-task-eip-${count.index}"
    }
}

resource "aws_key_pair" "my_key" {
  key_name = "my_key"
  public_key = file("~/.ssh/devops.pub")
}