output "ec2_public_ip" {
    description = "Public IP of ec2 instances"
    value = aws_eip.ec2_eip[0].public_ip
    depends_on = [ aws_eip.ec2_eip ]
}

output "db_endpoint" {
    description = "Database endpoint"
    value = aws_db_instance.db.address
}

output "db_port" {
    description = "Database port"
    value = aws_db_instance.db.port
}