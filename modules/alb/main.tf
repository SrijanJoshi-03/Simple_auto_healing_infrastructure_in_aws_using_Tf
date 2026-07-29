resource "aws_security_group" "lb_sg" {
    name = "${var.alb_config.name}_secirity_group"
    description = var.alb_config.description
    vpc_id = var.vpc_id
    ingress{
      from_port = var.sg_rules.from_port
      to_port = var.sg_rules.to_port
      protocol = var.sg_rules.protocol
      cidr_blocks = var.sg_rules.cidr_blocks
    }
    egress{
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
}
resource "aws_alb" "terraform_lb" {
  name = var.alb_config.name
  internal = var.alb_config.internal
  load_balancer_type = var.alb_config.type
  security_groups = [aws_security_group.lb_sg.id]
  subnets = var.subnet_ids
  enable_deletion_protection = true
  tags = {
    Name = var.alb_config.tags.Name
    Project = var.alb_config.tags.Project
  }
}

