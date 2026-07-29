
resource "aws_iam_role" "ec2_ecr_role" {
  name_prefix = "ec2-ecr-read-role-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  role       = aws_iam_role.ec2_ecr_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}


resource "aws_iam_instance_profile" "ec2_ecr_profile" {
  name_prefix = "ec2-ecr-profile-"
  role        = aws_iam_role.ec2_ecr_role.name
}

data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}
resource "aws_launch_template" "tf_launch_template" {
    image_id = "resolve:ssm:/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
    instance_type = "t2.micro"
    vpc_security_group_ids = var.sg_ids
    name_prefix = "tf-template-"
    tag_specifications {
        resource_type = "instance"
        tags = {
            Name = "tf_lt_instance"
        }
    }
    iam_instance_profile {
        name = aws_iam_instance_profile.ec2_ecr_profile.name
    }
    metadata_options {
        http_endpoint = "enabled"
        http_tokens = "required"
        http_put_response_hop_limit = 2
    }
    block_device_mappings {
        device_name = "/dev/xvda"
        ebs {
            volume_size = 20
            volume_type = "gp3"
            delete_on_termination = true
            encrypted = true
        }
    }
    key_name = var.key_config
    update_default_version = true
    tags = {
        Name = "tf_launch_template"
    }
    user_data = base64encode(var.user_data)
}