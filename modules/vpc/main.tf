resource "aws_vpc" "terraform_vpc" {
    cidr_block = var.vpc_config.cidr_block
    region = var.vpc_config.region
    tags = {
        Name = var.vpc_config.tags.Name
        Project = var.vpc_config.tags.Project
    }
    enable_dns_hostnames = var.vpc_config.enable_dns_hostnames
    enable_dns_support = var.vpc_config.enable_dns_support
}

resource "aws_subnet" "terraform_subnets" {
    vpc_id = aws_vpc.terraform_vpc.id
    for_each = var.subnet_config
    cidr_block = each.value.cidr_block
    availability_zone = each.value.availability_zone
    map_public_ip_on_launch = each.value.map_public_ip_on_launch
    tags = {
        Name = each.value.tags.Name
        Project = each.value.tags.Project
    }
    depends_on = [aws_vpc.terraform_vpc]
}
resource "aws_internet_gateway" "terraform_igw" {
    vpc_id = aws_vpc.terraform_vpc.id
    tags = {
        Name = var.igw_config.tags.Name
        Project = var.igw_config.tags.Project
    }
}