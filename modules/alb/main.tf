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
    tags = {
      Name = var.alb_config.tags.Name
      Project = var.alb_config.tags.Project
    }
}
resource "aws_alb" "terraform_lb" {
  name = var.alb_config.name
  internal = var.alb_config.internal
  load_balancer_type = var.alb_config.type
  security_groups = [aws_security_group.lb_sg.id]
  subnets = var.subnet_ids
  enable_deletion_protection = var.enable_deletion_protection
  tags = {
    Name = var.alb_config.tags.Name
    Project = var.alb_config.tags.Project
  }
}

resource "aws_lb_target_group" "tf_tg" {
  name        = "${var.alb_config.name}-tg"
  port        = var.target_group_config.port
  protocol    = var.target_group_config.protocol
  vpc_id      = var.vpc_id
  target_type = var.target_group_config.target_type

  health_check {
    enabled             = var.target_group_config.health_check.enabled
    path                = var.target_group_config.health_check.path
    protocol            = var.target_group_config.protocol
    healthy_threshold   = var.target_group_config.health_check.healthy_threshold
    unhealthy_threshold = var.target_group_config.health_check.unhealthy_threshold
    interval            = var.target_group_config.health_check.interval
    timeout             = var.target_group_config.health_check.timeout
    matcher             = var.target_group_config.health_check.matcher
  }

  tags = {
    Name    = "${var.alb_config.name}-tg"
    Project = var.alb_config.tags.Project
  }
}

resource "aws_lb_listener" "tf_listener" {
  load_balancer_arn = aws_alb.terraform_lb.arn
  port              = var.target_group_config.port
  protocol          = var.target_group_config.protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tf_tg.arn
  }
}
