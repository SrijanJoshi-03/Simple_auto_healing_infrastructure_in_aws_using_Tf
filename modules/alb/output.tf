output "target_group_arns" {
  description = "Target group ARN(s) for the ASG to attach to"
  value = [aws_lb_target_group.tf_tg.arn]
}
output "dns_name" {
  description = "Public DNS name of the ALB - hit this to see the page"
  value       = aws_alb.terraform_lb.dns_name
}
output "lb_security_group_id" {
  description = "ALB security group ID, used to authorize ingress on the EC2 SG"
  value       = aws_security_group.lb_sg.id
}
