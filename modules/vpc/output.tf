output "vpc_id" {
    description = "The ID of the VPC"
    value = aws_vpc.terraform_vpc.id
}
output "subnet_ids" {
  description = "vpc publci subnet ids"
  value = [for subnet in aws_subnet.terraform_subnets : subnet.id]
}

output "security_group_id" {
    description = "The ID of the shared EC2 security group"
    value = [aws_security_group.tf_ec2_sg.id]
}
