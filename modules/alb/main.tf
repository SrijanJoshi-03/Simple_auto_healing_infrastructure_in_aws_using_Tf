resource "aws_security_group" "lb_sg" {
    name = var.alb_config.name
    description = var.alb_config.description
    vpc_id = var.vpc_id
}