# EC2 Instance with PostgreSQL
resource "aws_instance" "postgres_ec2" {
  count = var.instance_settings.instance.count
  ami = var.instance_settings.instance.ami
  instance_type = var.instance_settings.instance.instance_type
  vpc_security_group_ids = [aws_security_group.postgres_sg.id]
  associate_public_ip_address = true
  subnet_id = aws_subnet.public_subnet[count.index].id
  key_name =  aws_key_pair.my_key.key_name

  user_data = <<EOF
#!/bin/bash
# Update and install PostgreSQL
apt-get update -y
apt-get install -y postgresql postgresql-contrib

# Start PostgreSQL service
systemctl start postgresql
systemctl enable postgresql

# Configure PostgreSQL
sudo -u postgres psql << 'PSQL'
CREATE USER ${var.db_user} WITH PASSWORD '${var.db_password}';
CREATE DATABASE nebo_db;
GRANT ALL PRIVILEGES ON DATABASE nebo_db TO ${var.db_user};
ALTER DATABASE nebo_db OWNER TO ${var.db_user};
\\q
PSQL

# Allow remote connections
echo "host all all 0.0.0.0/0 md5" >> /etc/postgresql/14/main/pg_hba.conf
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/14/main/postgresql.conf
systemctl restart postgresql

# Install pgLoader for migration
apt-get install -y pgloader
EOF

  tags = {
    Name = "PostgreSQL-EC2"
  }
}

resource "aws_eip" "ec2_eip_postgres" {
    count = var.instance_settings.instance.count
    instance = aws_instance.postgres_ec2[count.index].id
    tags = {
        Name = "nebo-task-eip-${count.index}"
    }
}