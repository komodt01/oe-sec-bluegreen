# OE + Security: Blue/Green (Reference)

**Purpose**: reference implementation of Blue/Green deployments aligned to the AWS Well-Architected *Operational Excellence* and *Security* pillars.

**Important**: This repo reflects AWS reference guidance; final choices MUST be driven by business objectives, risk, compliance, and cost—cloud/provider/tooling are selected *after* the objectives.

## Options we’ll demo
- **CodeDeploy (EC2/ASG)** – simplest, clear Blue/Green semantics, strong rollback.
- **Elastic Beanstalk** – managed Blue/Green via environment swap.
- **(Later) ECS + ALB + CodeDeploy** – containerized Blue/Green.

## What’s here
- `src/app/` – placeholder app.
- `iac/cdk/bluegreen/` – CDK skeleton for CodeDeploy EC2/ASG Blue/Green.
- `.github/workflows/` – CI to lint + synth; CD to come.
- `DEPLOYMENT.md` – how to operate Blue/Green safely.

## Security/Governance
- Policy-as-code hooks (pre-commit): ruff/black/bandit/detect-secrets.
- Branch protection, PR reviews, Dependabot, secret scanning (see SECURITY.md).

