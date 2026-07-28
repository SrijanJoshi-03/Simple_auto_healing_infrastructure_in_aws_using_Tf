module "vpc" {
  source        = "./modules/vpc"
  vpc_config    = var.vpc
  subnet_config = var.subnet
  igw_config = var.internet_gw
}