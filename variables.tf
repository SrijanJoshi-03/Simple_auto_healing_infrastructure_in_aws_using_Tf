variable "vpc" {
  type = object({
    cidr_block           = string
    region               = string
    tags                 = map(string)
    enable_dns_hostnames = bool
    enable_dns_support   = bool
  })
  default = {
    cidr_block = "10.16.0.0/16"
    region     = "us-east-1"
    tags = {
      Name    = "terraform-vpc"
      Project = "assesment_global_360"
    }
    enable_dns_hostnames = true
    enable_dns_support   = true
  }
}

variable "subnet" {
  type = map(object({
    name                    = string
    cidr_block              = string
    availability_zone       = string
    map_public_ip_on_launch = bool
    tags                    = map(string)
  }))
  default = {
    "Public_subnet_A" = {
      name                    = "Public_subnet_A"
      cidr_block              = "10.16.0.0/20"
      availability_zone       = "us-east-2a"
      map_public_ip_on_launch = true
      tags = {
        "Name"    = "Public_subnet_B"
        "Project" = "assesment_global_360"
      }
    }
    "Public_subnet_B" = {
      name                    = "Public_subnet_B"
      cidr_block              = "10.16.16.0/20"
      availability_zone       = "us-east-2b"
      map_public_ip_on_launch = true
      tags = {
        "Name"    = "Public_subnet_B"
        "Project" = "assesment_global_360"
      }
    }
  }
}

variable "internet_gw" {
  type = object({
    tags = map(string)
  })
  default = {
    tags = {
      Name    = "terraform-igw"
      Project = "assesment_global_360"
    }
  }
}

variable "alb" {
  type = object({
    name        = string
    description = string
    internal    = bool
    type        = string
    tags        = map(string)
  })
  default = {
    name        = "terraform-alb"
    internal    = false
    type        = "application"
    description = "terraform internet facing alb"
    tags = {
      Name    = "terraform-alb"
      Project = "assesment_global_360"
    }
  }
}

variable "ec2_sg" {
  type = object({
    name        = string
    description = string
    tags        = map(string)
  })
  default = {
    name        = "terraform-sg"
    description = "terraform sg for ec2 instances"
    tags = {
      Name    = "terraform-sg"
      Project = "assesment_global_360"
    }
  }
}

variable "lb_sg_rules" {
  type = object({
    from_port   = string
    to_port     = string
    protocol    = string
    cidr_blocks = list(string)
  })
  default = {
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}