variable "alb_config" {
    type = object({
      name = string
      description = string
      tags = map(string)
    })
}
variable "vpc_id" {
  type = string
}