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



