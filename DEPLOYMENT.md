# Deployment (Blue/Green)

## How it works (high-level)
1) **Green** (new version) is rolled out alongside **Blue** (live).
2) Health checks & tests run against Green.
3) **Traffic is shifted** (or environments are swapped).
4) **Automatic rollback** on failed alarms/health.

## Safe-ops guardrails
- Pre-deploy checks: unit tests, IaC synth, policy checks.
- Observability: ALB target health, CloudWatch alarms, error budgets.
- Rollback: CodeDeploy auto-rollback on alarm; manual swap procedures.

## Operate
- **Preview**: `cdk synth` → review the change set.
- **Deploy**: `cdk deploy --require-approval never` (non-prod).
- **Cutover**: CodeDeploy traffic shifting or Beanstalk env swap.
- **Rollback**: `codedeploy` rollback or Beanstalk swap back.
