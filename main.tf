module "vpc" {
  source        = "./modules/vpc"
  vpc_config    = var.vpc
  subnet_config = var.subnet
  igw_config    = var.internet_gw
}

module "alb" {
  source     = "./modules/alb"
  alb_config = var.alb
  depends_on = [module.vpc]
  vpc_id     = module.vpc.vpc_id
}