variable "asg_config" {
  
}
variable "vpc_id" {
  type = string
}
variable "subnet_ids" {
  type = list(string)
}
variable "sg_ids" {
  type = list(string)
}
variable "launch_template" {
  type = string
  
}
variable "target_group_arns" {
  type = list(string)
}