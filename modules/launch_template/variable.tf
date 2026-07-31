variable "key_config" {
  type = string
}

variable "sg_ids" {
  type = list(string)
}

variable "project_tag" {
  type    = string
  default = "assessment_global_360"
}

variable "region" {
  type = string
}

variable "account_id" {
  type = string
}

variable "image_name" {
  type = string
}

variable "image_tag" {
  type = string
}
