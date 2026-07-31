#!/bin/bash
set -euxo pipefail

# Update packages and install Docker + AWS CLI
dnf update -y
dnf install -y docker awscli

# Start and enable Docker
systemctl enable --now docker

REGION="${region}"
ACCOUNT_ID="${account_id}"
ECR_URL="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"
IMAGE_TAG="$ECR_URL/${image_name}:${image_tag}"

# Authenticate Docker against ECR (uses the instance's IAM role -
# see aws_iam_role.ec2_ecr_role / AmazonEC2ContainerRegistryReadOnly)
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ECR_URL"

# Pull and run the NGINX container, restart automatically on failure/reboot
docker pull "$IMAGE_TAG"
docker run -d --name nginx-container --restart always -p 80:80 "$IMAGE_TAG"