variable "asg_config" {
  type = object({
  name                      = string
  max_size                  = number
  min_size                  = number
  desired_capacity          = number
  health_check_grace_period = number
  health_check_type         = string
  force_delete              = bool
  })
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

variable "project_tag" {
  type    = string
  default = "assessment_global_360"
}