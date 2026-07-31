resource "aws_autoscaling_group" "tf_asg" {
  name                       = var.asg_config.name
  max_size                   = var.asg_config.max_size
  min_size                   = var.asg_config.min_size
  desired_capacity           = var.asg_config.desired_capacity
  health_check_grace_period  = var.asg_config.health_check_grace_period
  health_check_type          = var.asg_config.health_check_type
  force_delete                = var.asg_config.force_delete

  launch_template {
    id      = var.launch_template
    version = "$Latest"
  }
  vpc_zone_identifier = var.subnet_ids

  tag {
    key                 = "Name"
    value               = "tf-asg"
    propagate_at_launch = true
  }
  tag {
    key                 = "Project"
    value               = var.project_tag
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }

  termination_policies = ["OldestInstance"]
  target_group_arns    = var.target_group_arns
}