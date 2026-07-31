output "url" {
  description = "Open this in a browser once apply finishes"
  value       = "http://${module.alb.dns_name}"
}

output "asg_name" {
  description = "Auto Scaling Group name - useful for `aws autoscaling` CLI commands during testing"
  value       = module.asg.asg_name
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
