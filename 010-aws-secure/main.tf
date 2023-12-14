# Create S3 bucket for logs
resource "aws_s3_bucket" "bastion_logs" {
  bucket = "bastion-logs-mnowacki"
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "versioning_bation_logs" {
  bucket = aws_s3_bucket.bastion_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable VPC Flow Logs with S3 bucket
resource "aws_flow_log" "nebo_flow_log" {
  log_destination        = aws_s3_bucket.bastion_logs.arn
  log_destination_type   = "s3"
  traffic_type           = "ALL"
  vpc_id                 = aws_vpc.nebo_vpc.id
}

## EC2 Bastion Host Security Group
resource "aws_security_group" "ec2_bastion_sg" {
  description = "EC2 Bastion Host Security Group"
  name        = "ec2-bastion-sg"
  vpc_id      = aws_vpc.nebo_vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Open to Public Internet"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "IPv4 route Open to Public Internet"
  }
}

## EC2 Private Host Security Group
resource "aws_security_group" "ec2_private_sg" {
  description = "EC2 Private Host Security Group"
  name        = "ec2-private-sg"
  vpc_id      = aws_vpc.nebo_vpc.id
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "IPv4 route Open to Public Internet"
  }
}

## EC2 Bastion Host Elastic IP
resource "aws_eip" "ec2_bastion_host_eip" {
  vpc = true
  tags = {
    Name = "ec2-bastion-host-eip"
  }
}

## EC2 Bastion Host
resource "aws_instance" "ec2_bastion_host" {
  ami                         = "ami-0505148b3591e4c07"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.ec2_bastion_sg.id]
  subnet_id                   = aws_subnet.nebo_vpc_public_subnet.id
  iam_instance_profile        = aws_iam_instance_profile.ec2_bastion_host_instance_profile.name
  associate_public_ip_address = false
  user_data = <<-EOF
              #!/bin/bash
              sudo snap install amazon-ssm-agent --classic
              systemctl start amazon-ssm-agent
              systemctl enable amazon-ssm-agent
              EOF
  tags = {
    Name = "ec2-bastion-host"
  }
  lifecycle {
    ignore_changes = [
      associate_public_ip_address,
    ]
  }
}

## EC2 Bastion Host Elastic IP Association
resource "aws_eip_association" "ec2_bastion_host_eip_association" {
  instance_id   = aws_instance.ec2_bastion_host.id
  allocation_id = aws_eip.ec2_bastion_host_eip.id
}


## EC2 Private Host
resource "aws_instance" "private_host" {
  ami                         = "ami-0505148b3591e4c07"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.ec2_private_sg.id]
  subnet_id                   = aws_subnet.nebo_vpc_private_subnet.id
  associate_public_ip_address = false
  tags = {
    Name = "ec2-private-host"
  }
}

# Define Network ACL
resource "aws_network_acl" "nebo_network_acl" {
  vpc_id = aws_vpc.nebo_vpc.id
  ingress {
    rule_no  = 100
    action        = "allow"
    protocol      = "icmp"
    cidr_block    = "172.16.0.0/24"
    icmp_type     = -1  # -1 represents all ICMP types
    icmp_code     = -1  
    from_port     = 0
    to_port       = 0
  }
  egress {
    rule_no       = 100
    protocol      = "icmp"
    action        = "allow"
    cidr_block    = "172.16.0.0/24"
    icmp_type     = -1  # -1 represents all ICMP types
    icmp_code     = -1  
    from_port     = 0
    to_port       = 0
  }
}

# Associate the Network ACL with the Subnet
resource "aws_network_acl_association" "subnet_acl_association" {
  subnet_id          = aws_subnet.nebo_vpc_private_subnet.id
  network_acl_id     = aws_network_acl.nebo_network_acl.id
}