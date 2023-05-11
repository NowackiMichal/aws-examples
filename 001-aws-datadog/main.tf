locals {
  ssh_user	= "ubuntu"
  key_name	= "devops"
  private_key_path = "~/Terraform/aws/001-aws-datadog/devops.pem"
}

resource "aws_security_group" "allow-ssh" {
  name = "allow-ssh"
  description = "security group that allows ssh and all egress traffic"
 
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_instance" "my_instance" {
  ami                         = "ami-0ec7f9846da6b0f61"
  instance_type               = "t2.micro"
    
  security_groups             = [aws_security_group.allow-ssh.name]
  associate_public_ip_address = true
  key_name                    = local.key_name
  
  provisioner "remote-exec" {
    inline = ["echo 'Wait until SSH is ready'"]

    connection {
      type		= "ssh"
      user		= local.ssh_user
      private_key	= file(local.private_key_path)
      host		= aws_instance.my_instance.public_ip
    }
  }
  
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ${aws_instance.my_instance.public_ip}, --private-key ${local.private_key_path} playbook.yml"
  }
  
}

output "instance_ip" {
  value = aws_instance.my_instance.public_ip
}
