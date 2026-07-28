variable "vpc_config" {
  type = object({
    cidr_block = string
    region = string
    tags = map(string)
    enable_dns_hostnames= bool
    enable_dns_support = bool 
  })
}
variable "subnet_config" {
  type = map(object({
    name                    = string
    cidr_block              = string
    availability_zone       = string
    map_public_ip_on_launch = bool
    tags                    = map(string)
  })) 
}
variable "igw_config"{
    type = object({
      tags = map(string) 
    })
}