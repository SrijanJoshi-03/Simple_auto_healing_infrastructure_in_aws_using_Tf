variable "alb_config" {
    type = object({
      name = string
      internal = bool
      type = string
      description = string
      tags = map(string)
    })
}
variable "vpc_id" {
  type = string
}
variable "subnet_ids"{
  type = list(string)
}
variable "sg_ids"{
  type = list(string)
}

variable "sg_rules" {
  type = object({
    from_port = string
    to_port = string
    protocol = string
    cidr_blocks = list(string)
  })
}