# AWS CDK Blue/Green Infrastructure Scaffold

## Purpose

This directory contains the AWS CDK scaffold for the production blue/green architecture associated with this project.

The deployment lifecycle and security controls are demonstrated elsewhere in the repository. The infrastructure in this directory represents the next architectural layer required to implement Blue and Green runtime environments with controlled traffic promotion and rollback.

The full runtime architecture was not deployed as part of this project.

## Target Architecture

The intended AWS architecture includes:

- Application Load Balancer (ALB)
- Separate Blue and Green target groups
- EC2 launch template
- Auto Scaling Group capacity
- AWS CodeDeploy Application
- CodeDeploy Deployment Group
- Health monitoring
- CloudWatch alarms
- Automated rollback

## Intended Deployment Flow

The production pattern would operate as follows:

1. Blue serves the current production release.
2. Green capacity is prepared for the candidate release.
3. CodeDeploy deploys the candidate application to Green.
4. Deployment lifecycle hooks validate installation and application startup.
5. Green is evaluated using defined health and release criteria.
6. Traffic is promoted from the Blue target group to Green.
7. Operational and security telemetry is monitored after cutover.
8. Blue remains available for a defined rollback period.
9. If defined failure criteria are reached, traffic is returned to Blue.

## Why Separate Blue and Green Capacity?

The purpose of the design is to avoid modifying the environment currently serving users.

Separating the current and candidate releases provides:

- Isolation between the known-good and candidate versions
- Pre-cutover validation
- Controlled traffic promotion
- Faster recovery from a failed release
- Reduced dependence on repairing an unsuccessful deployment in place

The tradeoff is additional infrastructure cost and operational complexity while both environments exist.

## Health and Promotion Criteria

Successful deployment alone should not automatically authorize traffic promotion.

For a production implementation, I would evaluate signals such as:

- CodeDeploy lifecycle status
- ALB target health
- Application response
- Error rates
- Latency
- Critical dependency availability
- Application-specific functional checks
- CloudWatch alarms
- Security findings and telemetry

The appropriate signals and thresholds would depend on the application's business function and availability requirements.

## Rollback

The target design uses Blue as the known-good recovery environment during the release window.

Rollback should be possible when Green fails:

- Deployment validation
- Health checks
- Operational thresholds
- Security criteria
- Post-cutover monitoring

Automated rollback through CodeDeploy and CloudWatch alarms would be evaluated for conditions where an immediate response is preferable to manual intervention.

Manual rollback should remain available for scenarios that require operational judgment.

## Infrastructure Changes

Before deployment, CDK can synthesize the infrastructure definition for review:

```bash
cdk synth
