# Blue/Green Deployment Security Architecture Prototype

## Project Overview

This project explores how security and operational controls can be incorporated into a blue/green deployment process rather than treated as separate activities at the end of delivery.

The implemented portion focuses on deployment lifecycle controls, secrets detection, dependency maintenance, AWS CodeDeploy lifecycle hooks, and service health validation.

The repository also includes an AWS CDK scaffold representing a broader blue/green architecture using separate deployment capacity, load balancing, controlled traffic promotion, monitoring, and rollback.

The full ALB, Auto Scaling Group, target group, traffic-switching, and automated rollback infrastructure was not deployed as part of this project.

## Project Scope

### Implemented

- Pre-commit secrets detection using `detect-secrets`
- Dependabot configuration for dependency and GitHub Actions maintenance
- AWS CodeDeploy lifecycle hooks
- Application start and deployment validation scripts
- Local HTTP health validation
- Deployment documentation and blue/green architecture scaffold

### Architecture / Production Design

The production blue/green design extends the implemented deployment lifecycle with:

- Separate Blue and Green application capacity
- Application Load Balancer
- Separate target groups
- Controlled traffic promotion to Green
- CloudWatch health and application alarms
- Automated rollback when defined health criteria fail
- Retention of the previous environment during a defined rollback window

These components are represented as an architecture/CDK scaffold rather than a completed production deployment.

## Why Blue/Green?

An in-place deployment changes the environment currently serving users. If a new release introduces an application defect, configuration problem, security issue, or performance regression, recovery may require repairing or redeploying that same environment.

For this scenario, I used a blue/green pattern to separate the currently running version from the candidate release.

The intended flow is:

1. Blue continues serving production traffic.
2. Green receives the candidate release.
3. Deployment checks validate the candidate environment.
4. The application is started and health-checked.
5. In a production implementation, Green would be registered with a separate load balancer target group and validated before traffic promotion.
6. Traffic would shift to Green only after the required checks pass.
7. Blue would remain available during a defined rollback period.

The objective is to reduce deployment risk while providing a faster and more controlled recovery path when a release fails.

## Security and Deployment Control Flow

The project applies controls at different points in the delivery process rather than relying on a single deployment check.

### Developer Workstation

The pre-commit configuration uses `detect-secrets` to identify potential credential or secret exposure before changes are committed.

### Dependency Maintenance

Dependabot is configured to check supported dependency ecosystems and GitHub Actions on a weekly schedule and create update pull requests according to the configured policy.

Dependency updates would still require review and validation before promotion into a production environment.

### Deployment

AWS CodeDeploy lifecycle hooks define the deployment sequence:

`BeforeInstall → AfterInstall → ApplicationStart → ValidateService`

The `ValidateService` hook performs a local HTTP health check against the service on port 8080. If the endpoint does not respond successfully, the validation script fails.

This provides a basic deployment control that can be expanded into broader promotion criteria in a production implementation.

## Health Validation

The implemented health check verifies that the deployed service responds successfully after startup.

This is intentionally a basic validation.

For a production workload, I would evaluate additional signals such as:

- Load balancer target health
- Critical application dependency availability
- Error rates
- Latency
- Application-specific functional checks
- CloudWatch alarms
- Security telemetry

Traffic promotion should depend on the signals that demonstrate the application can safely perform its required business function, not simply that a process is running.

## Rollback Strategy

The production architecture would retain Blue while Green is introduced and validated.

If Green fails deployment validation, health checks, or defined operational thresholds, traffic should remain on or return to Blue.

The specific rollback criteria and the amount of time Blue remains available would depend on factors such as application criticality, recovery objectives, deployment frequency, infrastructure cost, and organizational change policy.

## Architecture Boundary

This repository is an architecture prototype, not a completed production blue/green platform.

It demonstrates deployment lifecycle controls and documents how those controls would fit into a broader AWS blue/green architecture.

The infrastructure scaffold represents the intended architecture but should not be interpreted as evidence that the complete runtime environment was deployed.

A production implementation would require additional evaluation of:

- Networking and segmentation
- IAM and deployment identities
- TLS and certificate management
- Load balancing and target-group configuration
- Monitoring and observability
- Promotion and rollback thresholds
- Secrets management
- Data-tier and schema compatibility
- Resilience and recovery requirements
- Application-specific health criteria

## Key Technologies

- GitHub
- GitHub Dependabot
- detect-secrets
- AWS CodeDeploy
- AWS CDK
- Bash

## Repository Structure

- `app/scripts/` — CodeDeploy lifecycle and health-check scripts
- `iac/cdk/bluegreen/` — blue/green infrastructure architecture scaffold
- `.pre-commit-config.yaml` — local secrets detection
- `dependabot.yml` — dependency maintenance configuration
- `DEPLOYMENT.md` — deployment architecture and operational considerations
- `SECURITY.md` — security controls and production security considerations

## Production Considerations

This project intentionally stops short of representing a complete production deployment.

Before implementing this architecture for a real workload, I would first establish the application's business criticality, availability requirements, recovery objectives, deployment frequency, security requirements, and acceptable rollback window.

Those requirements would drive the final decisions around traffic-shifting strategy, health criteria, monitoring, rollback automation, infrastructure capacity, security controls, and operational ownership.
