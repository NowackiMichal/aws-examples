variable "aws_region" {
    default = "eu-central-1"
}

variable "vpc_cidr_block" {
    description = "CIDR block for nebo-vnet"
    type = string
    default = "10.0.0.0/16"
}

variable "subnet_count" {
    description = "Number of subnets"
    type = map(number)
    default = {
      "public" = 1
      "private" = 2
    }
}

variable "instance_settings" {
    description = "Settings of instances"
    type = map(any)
    default = {
      "database" = {
        identifier          = "nebo-task"
        allocated_storage   = 10
        name                = "nebotask"
        engine              = "mysql"
        engine_version      = "5.7"
        instance_class      = "db.t3.micro"
        skip_final_snapshot = true
        deletion_protection = false
      },
      "instance" = {
        count               = 1
        instance_type       = "t2.micro"
        ami                 = "ami-04e601abe3e1a910f"
      }
    }
}   

variable "private_subnet_cidr_blocks" {
    description = "CIDR blocks for private subnet"
    type = list(string)
    default = [ "10.0.101.0/24",
                "10.0.102.0/24",
                "10.0.103.0/24",
                "10.0.104.0/24",
     ]
}

variable "public_subnet_cidr_blocks" {
    description = "CIDR blocks for public subnet"
    type = list(string)
    default = [ "10.0.1.0/24",
                "10.0.2.0/24",
                "10.0.3.0/24",
                "10.0.4.0/24",
     ]
}

variable "db_user" {
   type = string
}

variable "db_password" {
   type  = string
}