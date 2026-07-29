module "vpc" {
  source        = "./modules/vpc"
  vpc_config    = var.vpc
  subnet_config = var.subnet
  sg_config     = var.ec2_sg
  igw_config    = var.internet_gw
}

module "alb" {
  source     = "./modules/alb"
  alb_config = var.alb
  depends_on = [module.vpc]
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.subnet_ids
  sg_ids     = module.vpc.security_group_id
  sg_rules   = var.lb_sg_rules
}

module "asg" {
  source            = "./modules/asg"
  asg_config        = var.asg
  depends_on        = [module.vpc, module.alb]
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.subnet_ids
  sg_ids            = module.vpc.security_group_id
  launch_template   = module.launch_template.launch_template
  target_group_arns = module.alb.target_group_arns
}

module "launch_template" {
  source      = "./modules/launch_template"
  lt_config   = var.launch_template
  depends_on  = [module.vpc]
  vpc_id      = module.vpc.vpc_id
  sg_ids      = module.vpc.security_group_id
  http_proxy  = var.http_proxy
  https_proxy = var.https_proxy
  no_proxy    = var.no_proxy
  user_data   = var.user_data
  key_config  = var.key_pair_name
}


