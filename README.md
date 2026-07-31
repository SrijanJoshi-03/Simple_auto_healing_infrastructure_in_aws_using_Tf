# Simple_auto_healing_infrastructure_in_aws_using_Tf
Auto-healing, containerised NGINX web tier on AWS — Terraform-provisioned ASG + ALB, instances bootstrap via user-data to pull and run a Docker image.

# Auto-Healing Web Tier (AWS, Terraform)

A self-healing, N+1 NGINX web tier on AWS: an Application Load Balancer in
front of an Auto Scaling Group running a containerised NGINX page. Terminate
any single instance and the ASG replaces it automatically, with zero manual
steps and zero downtime for the other instance(s).

## Why AWS over Azure

AWS was chosen because the required primitives map onto services with the
cleanest managed "just works" behavior for this specific brief:

- **Auto Scaling Group + ALB target-group health checks** give self-healing
  and N+1 out of the box with no extra glue (no Function App / Logic App
  needed, unlike replicating this on Azure VMSS + health extensions).
- **SSM Parameter Store `resolve:` syntax** lets the launch template always
  boot the latest Amazon Linux 2023 AMI without a lookup `data` block or a
  hardcoded, quickly-stale AMI ID.
- Personal familiarity with the AWS provider meant less time debugging
  provider quirks and more time on the actual architecture - a reasonable
  and disclosed reason for either cloud in a take-home like this.

Either AWS (ASG+ALB) or Azure (VMSS+Load Balancer/App Gateway) would satisfy
the brief equally well; this is a preference, not a claim that AWS is
objectively superior for this use case.

## Architecture

```mermaid
flowchart TB
    Internet((Internet)) --> ALB[Application Load Balancer<br/>public subnets, port 80]
    ALB --> TG[Target Group<br/>health check: GET / -> 200]
    TG --> EC2A[EC2 instance A<br/>t2.micro, AZ us-east-1a]
    TG --> EC2B[EC2 instance B<br/>t2.micro, AZ us-east-1b]

    subgraph ASG[Auto Scaling Group  min=1 desired=2 max=3]
        EC2A
        EC2B
    end

    EC2A -.cloud-init pulls image.-> ECR[(ECR repository<br/>nginx image)]
    EC2B -.cloud-init pulls image.-> ECR

    subgraph VPC[VPC 10.16.0.0/16]
        subgraph PubA[Public subnet A]
            EC2A
        end
        subgraph PubB[Public subnet B]
            EC2B
        end
    end

    IGW[Internet Gateway] --- VPC
```

**Self-healing loop:** the ALB target group health-checks each instance on
`GET /`. If an instance is terminated (or fails health checks), the ASG's
`health_check_type = "ELB"` setting detects it, launches a replacement from
the launch template in the same subnet pool, and the target group picks it
up automatically once it passes health checks — no human involved.

## Prerequisites

1. Terraform >= 1.9, AWS CLI configured with credentials that can create
   VPC/EC2/ALB/IAM/ASG resources.
2. An S3 bucket for remote state must already exist (S3 backends don't
   create their own bucket): the bucket named in `backend.tf`
   (`remote-backend-for-terraform-statefile-practice-2026`) in `us-east-1`,
   or edit `backend.tf` to point at your own / switch to a local backend
   for a quick first run:
   ```
   terraform init -backend=false
   ```
3. An ECR repository containing the built image (see **Containerisation**
   below), or override `image_name`/`image_tag`/`ecr_account_id` in
   `terraform.tfvars` to point at your own registry image.

## Run it

```bash
terraform init
terraform validate
terraform plan
terraform apply          # type 'yes' to confirm
```

Re-running `terraform plan` / `terraform apply` immediately after a clean
apply should show **no changes** — everything here is declarative with no
`count`/index-based resources that drift on re-run.

```bash
terraform output url     # -> http://<alb-dns-name>
```

Tear down:

```bash
terraform destroy
```

(`enable_alb_deletion_protection` defaults to `false` specifically so
`destroy` doesn't require a manual console step first — flip it to `true`
for anything long-lived.)

## Testing self-healing

```bash
# find a running instance ID from the ASG
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "$(terraform output -raw asg_name)" \
  --query 'AutoScalingGroups[0].Instances[].InstanceId' --output text

# terminate one
aws ec2 terminate-instances --instance-ids <instance-id>

# watch the ASG bring up a replacement - the OTHER instance keeps
# serving traffic the whole time, so the ALB URL stays up
watch aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "$(terraform output -raw asg_name)"
```

## Containerisation (bonus)

- `dockerfile` — `nginx:alpine` + the static `index.html`.
- Build & push to ECR (or swap for GHCR/Docker Hub and adjust the
  `image_*` variables and the pull step in
  `modules/launch_template/templates/user_data.sh.tpl` accordingly):
  ```bash
  aws ecr create-repository --repository-name my-nginx-app --region us-east-1
  aws ecr get-login-password --region us-east-1 | \
    docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
  docker build -t my-nginx-app .
  docker tag my-nginx-app:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/my-nginx-app:latest
  docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/my-nginx-app:latest
  ```
- Each instance's `user_data` (rendered from the template above at launch)
  authenticates to ECR using its instance IAM role
  (`AmazonEC2ContainerRegistryReadOnly` — read-only, least privilege),
  pulls the image, and runs it with `--restart always`.

## Alternative architectures considered

The brief is satisfied by the ASG + EC2 + Docker approach actually built
here, but two other designs were considered and are worth documenting —
both as evidence of the trade space explored, and as a roadmap for anyone
extending this repo.

### Option A: ECS on Fargate instead of ASG + EC2 + Docker

Rather than launching EC2 instances that pull and run a container via
user-data, the web tier could run as an **ECS service on Fargate**, with
the ALB pointed at the service instead of at instance targets.

**What would change:**
- No EC2 instances, launch template, AMI, or SSH key pair — that whole
  surface area (including the `tls_private_key`/`local_file` key-pair
  generation this repo currently does) goes away entirely.
- ALB target group type changes from `instance` to `ip` (Fargate tasks get
  their own ENIs).
- Self-healing moves from ASG + ELB-health-check to the **ECS service
  scheduler**: same outcome (unhealthy task killed, replacement placed),
  different owner.
- New resources: `aws_ecs_cluster`, `aws_ecs_task_definition` (points at
  the ECR image directly — no user-data pull step needed),
  `aws_ecs_service` with `desired_count = 2`, plus
  `deployment_minimum_healthy_percent` / `deployment_maximum_percent` for
  rolling replacement.
- IAM changes: a task execution role (ECR pull + CloudWatch Logs write)
  replaces the EC2 instance profile.

**Trade-offs vs. the current EC2 approach:**

| | EC2 + ASG (current) | ECS Fargate |
|---|---|---|
| OS patching | your problem | AWS's problem (no OS to manage) |
| Cold-start on replace | ~1–2 min (instance boot + user-data + docker pull) | ~30–60s (just an image pull, no OS boot) |
| Cost at this scale | ~$17/mo compute (Free Tier eligible) | pricier per-vCPU/GB than t2.micro; no EBS or AMI management cost, but **no Fargate free tier** |
| SSH access | yes, via key pair | no SSH — `ecs exec` only |
| Complexity added | — | cluster, task definition, service, IP-target-group wiring, execution role, mandatory CloudWatch log group |
| Budget impact | fits AUD 20 target only if destroyed after use | likely **increases** monthly cost relative to EC2, working against the AUD 20 budget noted below |

A nice side effect worth calling out: removing EC2 entirely also removes
the SSH key pair and its associated sensitive-file handling
(`tls_private_key` / `local_file.private_key` written to disk) — one less
secret to manage and gitignore correctly.

### Option B: Baked (golden) AMI instead of stock AMI + user-data

Instead of resolving the latest stock Amazon Linux 2023 AMI via SSM at
launch time and installing Docker / pulling the image via user-data, a
custom AMI could be pre-built (most commonly with **Packer**) that already
has Docker installed and the application image either pre-pulled or baked
directly into the filesystem.

**What would change:**
- The launch template's `image_id` would point at the custom AMI instead
  of `data.aws_ssm_parameter.al2023_ami`'s `resolve:` value.
- User-data shrinks to just `docker run` (or nothing at all, if the AMI
  bakes in a systemd unit / `docker-compose` that starts on boot) — no
  `dnf install docker`, no ECR login/pull at boot time.

**Trade-offs:**

| | Current (stock AMI + user-data) | Baked AMI |
|---|---|---|
| Boot-to-healthy time | slower — installs Docker and pulls the image on every single launch | faster — image already local, container just starts |
| Always-latest AMI | yes, automatic via SSM `resolve:` | no — AMI lifecycle becomes something you own |
| New pipeline needed | none | Packer build + a way to publish the new AMI id into the launch template (manual var bump, or CI) |
| Best fit for | infrequent app changes, simplicity | frequent scale-out events, or when fast recovery time matters most |

This option directly strengthens the "auto-healing" story: a scale-out or
replacement event finishing in seconds rather than over a minute is a
meaningfully better answer to "how fast does this heal?" — the trade-off
is taking on AMI build/publish lifecycle in exchange.

### Why neither was implemented here

Both are legitimate improvements over the current design, but out of
scope for this take-home given time constraints: Fargate is a bigger
architectural rewrite (new resource types, new IAM model, cost profile
that risks the budget target), and a baked-AMI pipeline needs a Packer
build step and a publishing mechanism that don't exist yet. They're
recorded here as the natural next iterations rather than implemented,
so the trade-offs are visible even though the code isn't.

## Assumptions

- Single region (`us-east-1`), two public subnets across two AZs — no NAT
  gateway / private subnets, since this is a stateless static web tier and
  a NAT gateway alone would blow the cost budget below.
- State is stored remotely in S3 with native S3 locking (`use_lockfile`,
  Terraform >= 1.10 pattern) instead of a DynamoDB lock table.
- `key_pair_name` defaults to `"terraform-key"` — create that key pair (or
  override the variable) before applying if you need SSH access; it isn't
  required for the app to function.
- No HTTPS/ACM certificate — port 80 only, to keep the demo self-contained.
  Add an `aws_acm_certificate` + a 443 listener for anything real.

## Estimated monthly cost (if left running continuously)

| Resource | Estimate (USD/mo) |
|---|---|
| 2× t2.micro (desired capacity) | ~$17 (or ~$0 if AWS Free Tier–eligible account, 750 hrs/mo for 12 months) |
| Application Load Balancer (fixed hourly charge) | ~$16–18 |
| ALB LCU usage (near-zero demo traffic) | ~$1–2 |
| 2× 20 GB gp3 EBS | ~$3 |
| **Total** | **~$37/mo (~AUD 55–60) continuously, or ~$20/mo (~AUD 30) on Free Tier** |

**This exceeds the AUD 20 target if left running 24/7** — the ALB's fixed
hourly charge (no free tier) is the dominant cost, not the EC2 instances.
To stay within budget: `terraform apply` for the grading/demo window, then
`terraform destroy` immediately after. Realistically there's no way to keep
an always-on ALB + 2 instances under AUD 20/month; that's a genuine
trade-off of the "N+1 behind a load balancer" requirement versus a single
low-cost instance, and it's worth flagging explicitly rather than quoting
an unrealistic figure.

## Known limitations / follow-ups

- No HTTPS.
- No CI pipeline yet building/pushing the image or running
  `terraform validate`/`plan` on PRs (optional in the brief, not yet
  implemented here).
- No CloudWatch alarms/SNS notifications — self-healing relies solely on
  native ASG + ELB health checks, which is sufficient for the stated
  requirement but wouldn't page anyone.
- ECS on Fargate and a baked-AMI launch path (see **Alternative
  architectures considered**) are documented but not implemented.