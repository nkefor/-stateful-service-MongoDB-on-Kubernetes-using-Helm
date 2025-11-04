# AWS Infra + CI/CD Sample

Enterprise-style reference implementation that deploys a sample containerized web app to AWS using:

- Terraform (VPC, ECS on Fargate, ALB, ECR, CloudWatch)
- GitHub Actions (OIDC to AWS, build and push image, Terraform deploy)
- Optional EC2 bastion host (disabled by default)

## What’s Included

- `infra/` Terraform for VPC, subnets, NAT, ALB, ECS Fargate service, ECR repo, IAM roles, CloudWatch Logs + alarms
- `app/` Minimal Node.js Express app with Dockerfile
- `.github/workflows/` CI (lint/build) + CD (build+push image, Terraform apply)

## Prerequisites

- AWS account with permissions to create IAM roles, VPC, ECS, ECR, ALB, CloudWatch, S3, DynamoDB
- GitHub repository (this repo) with Actions enabled

## One-Time Setup

1) Create GitHub OIDC role in AWS (manual, once):
   - Option A (recommended): Use `infra/iam-github-oidc` with your admin creds locally to create the role.
   - Option B: Create via AWS Console following AWS docs for GitHub OIDC. Trust policy must allow your `org/repo:ref:refs/heads/main` (adjust as needed) and grant permissions for ECR, ECS, EC2, ALB, CloudWatch, S3 (state), DynamoDB (lock), IAM pass roles for ECS.

   Save the created role ARN for the next step.

2) Add GitHub Secrets in your repo:
   - `AWS_ROLE_ARN` — The role ARN created above.
   - `AWS_REGION` — e.g. `us-east-1`.
   - `TF_STATE_BUCKET` — S3 bucket name to hold Terraform state (the workflow will create if missing).
   - `TF_LOCK_TABLE` — DynamoDB table name to hold state locks (e.g. `terraform-locks`; workflow will create if missing).

3) (Optional) Adjust defaults in `infra/variables.tf` (project name, environment, desired count, etc.).

## How Deploy Works (CD pipeline)

On push to `main` (paths `app/**` or `infra/**`):
- Configure AWS via OIDC and ensure S3 (state) + DynamoDB (lock) exist
- Terraform init (S3 backend), then apply only ECR repo to ensure it exists
- Build and push Docker image to ECR (tagged with commit SHA + `latest`)
- Terraform apply full stack with `image_tag` set to the commit SHA

Outputs include the ALB DNS name to access the app.

## Local Development

- App run: `cd app && npm install && npm start` (listens on `3000`).
- Build image: `docker build -t sample-app:dev ./app`.

## Terraform State

- Backend is S3. The workflow creates the S3 bucket + DynamoDB table if missing, then runs `terraform init` with `-backend-config`.

## Optional EC2 Bastion

- Enable by setting `enable_bastion = true` (e.g. via `TF_VAR_enable_bastion=true` in the workflow or local CLI). Creates a small SSM-managed instance in a public subnet.

## Clean Up

- Destroy: In GitHub, temporarily disable CD workflow, then run Terraform destroy locally with suitable AWS creds: `cd infra && terraform init && terraform destroy -var image_tag=latest`.

