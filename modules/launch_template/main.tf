
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.18-x86_64"
}
resource "aws_launch_template" "tf_launch_template" {
    image_id = data.aws_ssm_parameter.al2023_ami.value
    instance_type = "t2.micro"
    vpc_security_group_ids = var.sg_ids
    key_name = var.key_config
    update_default_version = true
    tags = {
        Name = "tf_launch_template"
    }
}