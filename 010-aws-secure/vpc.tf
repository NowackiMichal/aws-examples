# VPC
resource "aws_vpc" "nebo_vpc" {
  cidr_block = "172.16.0.0/16"
  tags = {
    Name = "nebo-vnet"
  }
}

## VPC Internet Gateway
resource "aws_internet_gateway" "nebo_vpc_igw" {
  vpc_id = aws_vpc.nebo_vpc.id
  tags = {
    Name = "nebo-IGW"
  }
}

## Elastic IP for NAT Gateway
resource "aws_eip" "nat_gateway_eip" {
  vpc = true
  tags = {
    Name = "nebo-nat-gateway-eip"
  }
}

## VPC NAT(Network Address Translation) Gateway
resource "aws_nat_gateway" "nebo_vpc_nat_gateway" {
  allocation_id = aws_eip.nat_gateway_eip.id
  subnet_id     = aws_subnet.nebo_vpc_public_subnet.id
  tags = {
    Name = "nebo-nat-gateway"
  }
}

## Public Subnet
resource "aws_subnet" "nebo_vpc_public_subnet" {
  vpc_id            = aws_vpc.nebo_vpc.id
  cidr_block        = "172.16.0.0/24"
  availability_zone = "eu-west-2a"
  tags = {
    Name = "nebo-public-subnet"
  }
}

## Route Table for Public Subnet
resource "aws_route_table" "public_subnet_rtb" {
  vpc_id = aws_vpc.nebo_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.nebo_vpc_igw.id
  }
  tags = {
    Name = "nebo-rtb-public-subnet"
  }
}

## Route Table Association for Public Subnet
resource "aws_route_table_association" "public_subnet_rtb_association" {
  subnet_id      = aws_subnet.nebo_vpc_public_subnet.id
  route_table_id = aws_route_table.public_subnet_rtb.id
}

## Private Subnet
resource "aws_subnet" "nebo_vpc_private_subnet" {
  vpc_id            = aws_vpc.nebo_vpc.id
  cidr_block        = "172.16.1.0/24"
  availability_zone = "eu-west-2a"
  tags = {
    Name = "nebo-private-subnet"
  }
}

## Route Table for Private Subnet 1
resource "aws_route_table" "private_subnet_rtb" {
  vpc_id = aws_vpc.nebo_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nebo_vpc_nat_gateway.id
  }
  tags = {
    Name = "nebo-rtb-private-subnet"
  }
}

## Route Table Association for Private Subnet 1
resource "aws_route_table_association" "private-subnet-1-rtb-association" {
  subnet_id      = aws_subnet.nebo_vpc_private_subnet.id
  route_table_id = aws_route_table.private_subnet_rtb.id
}