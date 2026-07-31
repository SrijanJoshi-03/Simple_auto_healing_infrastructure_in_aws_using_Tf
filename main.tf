module "vpc" {
  source        = "./modules/vpc"
  vpc_config    = var.vpc
  subnet_config = var.subnet
  sg_config     = var.ec2_sg
  igw_config    = var.internet_gw
}

module "alb" {
  source                     = "./modules/alb"
  alb_config                 = var.alb
  depends_on                 = [module.vpc]
  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.subnet_ids
  sg_ids                     = module.vpc.security_group_id
  sg_rules                   = var.lb_sg_rules
  target_group_config        = var.target_group
  enable_deletion_protection = var.enable_alb_deletion_protection
}

module "asg" {
  source            = "./modules/asg"
  asg_config        = var.asg
  depends_on        = [module.vpc, module.alb]
  subnet_ids        = module.vpc.subnet_ids
  sg_ids            = module.vpc.security_group_id
  launch_template   = module.launch_template.launch_template
  target_group_arns = module.alb.target_group_arns
}

module "launch_template" {
  source     = "./modules/launch_template"
  depends_on = [module.vpc]
  sg_ids     = module.vpc.security_group_id
  key_config = var.key_pair_name
  region     = var.vpc.region
  account_id = var.ecr_account_id
  image_name = var.image_name
  image_tag  = var.image_tag
}
resource "aws_security_group_rule" "allow_alb_to_ec2" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = one(module.vpc.security_group_id)
  source_security_group_id = module.alb.lb_security_group_id
  description              = "Allow HTTP from the ALB security group"
}




