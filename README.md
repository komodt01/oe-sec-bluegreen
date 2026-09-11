# Blue/Green Deployment Security Architecture Prototype

## Project Overview

This project explores how security controls can be integrated into a blue/green application deployment process without making security a separate activity at the end of delivery.

The implemented portion focuses on the security and deployment lifecycle: pre-commit checks, static application security testing, dependency maintenance, build-time scanning, AWS CodeDeploy lifecycle hooks, and application health validation.

The repository also includes a CDK scaffold for an AWS blue/green architecture using separate deployment capacity, load balancing, traffic switching, monitoring, and rollback. The full ALB/Auto Scaling Group blue/green runtime infrastructure was not deployed as part of this project.

## Project Scope

### Implemented

- GitHub CodeQL analysis for Python and JavaScript
- CodeQL execution on pull requests, pushes to `main`, and a weekly schedule
- Dependabot configuration for Python, npm, and GitHub Actions dependencies
- Pre-commit security and quality checks using Bandit, detect-secrets, Ruff, and Black
- Build-time Bandit scanning
- AWS CodeDeploy lifecycle hooks
- Application start and local health validation
- Application artifact packaging

### Architecture / Production Design

The production blue/green design extends the implemented deployment lifecycle with:

- Separate Blue and Green application capacity
- Application Load Balancer
- Separate target groups
- Controlled traffic promotion to Green
- CloudWatch health and application alarms
- Automated rollback when defined health criteria fail
- Retention of the previous environment during the rollback window

These components are represented as an architecture/CDK scaffold rather than a completed production deployment.

## Why Blue/Green?

An in-place deployment changes the environment currently serving users. If the new release introduces an application defect, security issue, configuration problem, or performance regression, recovery can require repairing or redeploying the same environment.

For this scenario, I used a blue/green pattern to separate the currently running version from the candidate release.

The intended flow is:

1. Blue continues serving production traffic.
2. Green receives the candidate application version.
3. Security and deployment checks validate the candidate.
4. The application is started and health-checked.
5. In a production implementation, Green would be registered with a separate load balancer target group and validated before traffic promotion.
6. Traffic would shift to Green only after the required checks pass.
7. Blue would remain available during a defined rollback period.

The objective is to reduce deployment risk while providing a faster and more controlled recovery path when a release fails.

## Security Control Flow

The project applies controls at multiple stages rather than relying on a single security scan.

**Developer Workstation**

Pre-commit controls provide early feedback:

- Bandit for Python security checks
- detect-secrets for potential credential or secret exposure
- Ruff for linting
- Black for formatting

**Source Control / Pull Request**

GitHub CodeQL performs static application security testing for Python and JavaScript. Pull-request analysis allows security findings to be identified before code is merged.

**Dependency Maintenance**

Dependabot checks Python, npm, and GitHub Actions dependencies on a weekly schedule and creates update PRs according to the configured policy.

**Build**

AWS CodeBuild installs and runs Bandit against the application before packaging the application artifact.

The current build configuration records Bandit findings without failing the build. In a production implementation, blocking thresholds would be defined according to vulnerability severity, confidence, application criticality, and the organization's exception process.

**Deployment**

AWS CodeDeploy lifecycle hooks control application installation and startup:

`BeforeInstall → AfterInstall → ApplicationStart → ValidateService`

The `ValidateService` hook performs a local HTTP health check against the application on port 8080. A failed health check causes the validation script to fail.

## Health Validation

The implemented health check confirms that the candidate application responds successfully after startup.

This is intentionally a basic validation.

For a production workload, I would evaluate additional checks such as:

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

If Green fails deployment validation, health checks, or defined operational alarms, traffic should remain on or return to Blue.

Rollback criteria and the amount of time Blue remains available would depend on the application's business criticality, recovery objectives, deployment frequency, infrastructure cost, and organizational change policy.

## Architecture Boundary

This repository is an architecture prototype, not a complete production blue/green platform.

It demonstrates the security automation and deployment lifecycle controls and documents how those controls fit into a broader AWS blue/green architecture.

A production implementation would still require detailed evaluation of networking, IAM, TLS, load balancing, monitoring, rollback thresholds, secrets management, data-tier compatibility, resilience requirements, and application-specific health criteria.

## Key Technologies

- GitHub Actions
- GitHub CodeQL
- Dependabot
- Bandit
- detect-secrets
- Ruff
- Black
- AWS CodeBuild
- AWS CodeDeploy
- AWS CDK
- Bash
- Python / JavaScript security analysis

## Repository Structure

- `.github/workflows/` — CodeQL and CI/security automation
- `app/scripts/` — CodeDeploy lifecycle and health-check scripts
- `iac/cdk/bluegreen/` — blue/green infrastructure scaffold
- `.pre-commit-config.yaml` — local security and quality controls
- `DEPLOYMENT.md` — deployment architecture and operational considerations
- `SECURITY.md` — security controls and production security considerations
- `README_CodeQL.md` — detailed CodeQL implementation notes

## Production Considerations

This project intentionally stops short of representing the prototype as a production-ready platform.

Before production adoption, I would work with application, platform, security, networking, and business stakeholders to define:

- Release and rollback criteria
- Acceptable deployment risk
- Required security gates
- Availability and recovery objectives
- Application health indicators
- Approval and exception processes
- Monitoring and incident escalation
- Cost implications of maintaining parallel capacity
- Database and schema compatibility during rollback

The specific implementation should follow the application's business requirements rather than adopting blue/green deployment simply because the pattern is available.
