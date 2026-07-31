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
      availability_zone       = "us-east-1a"
      map_public_ip_on_launch = true
      tags = {
        "Name"    = "Public_subnet_B"
        "Project" = "assesment_global_360"
      }
    }
    "Public_subnet_B" = {
      name                    = "Public_subnet_B"
      cidr_block              = "10.16.16.0/20"
      availability_zone       = "us-east-1b"
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

variable "key_pair_name" {
  type    = string
  default = "terraform-key"
}

variable "asg" {
  type = object({
    name                      = string
    max_size                  = number
    min_size                  = number
    desired_capacity          = number
    health_check_grace_period = number
    health_check_type         = string
    force_delete              = bool
  })
  default = {
    name                      = "tf_asg"
    min_size                  = 1
    max_size                  = 3
    desired_capacity          = 2
    health_check_grace_period = 300
    health_check_type         = "ELB"
    force_delete              = true
  }
}


variable "target_group" {
  type = object({
    protocol     = string
    port         = number
    target_type  = string
    health_check = map(string)
    action       = string
  })
  default = {
    protocol    = "HTTP"
    port        = 80
    target_type = "instance"
    health_check = {
      enabled             = true
      path                = "/"
      healthy_threshold   = 2
      unhealthy_threshold = 3
      timeout             = 5
      interval            = 15
      matcher             = "200"
    }
    action = "forward"
  }
}
variable "ecr_account_id" {
  description = "AWS account ID that owns the ECR repository the instances pull from"
  type        = string
  default     = "123456789012" # placeholder - override in terraform.tfvars
}

variable "image_name" {
  description = "ECR repository name (image) instances pull on boot"
  type        = string
  default     = "my-nginx-app"
}

variable "image_tag" {
  description = "Image tag to pull"
  type        = string
  default     = "latest"
}

variable "enable_alb_deletion_protection" {
  description = "Set true for long-lived/production; false makes `terraform destroy` work without a manual console step first (handy for a demo on a tight budget)."
  type        = bool
  default     = false
}