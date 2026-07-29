resource "aws_autoscaling_group" "tf_asg" {
  name                      = "tf-asg"
  max_size                  = 3
  min_size                  = 1
  desired_capacity          = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  force_delete              = true

  launch_template {
    id      = var.launch_template
    version = "$Latest"
  }
  vpc_zone_identifier = var.sg_ids

  tag {
    key                 = "Name"
    value               = "tf-asg"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }

  termination_policies = ["OldestInstance"]
  target_group_arns    = var.target_group_arns
}