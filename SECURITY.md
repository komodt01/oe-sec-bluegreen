# Security Controls and Production Considerations

## Purpose

This project applies security controls across the software delivery lifecycle rather than relying on a single scan or review step.

The implemented controls focus on developer-side checks, source-code analysis, dependency maintenance, build-time scanning, deployment validation, and protected promotion.

Some runtime and infrastructure controls are part of the production design rather than fully implemented components in this repository.

## Implemented Security Controls

### Pre-Commit Controls

The repository uses pre-commit hooks to provide feedback before code is committed.

Configured controls include:

- Bandit for Python security analysis
- detect-secrets for potential credential or secret exposure
- Ruff for linting and code-quality checks
- Black for formatting

These controls help identify issues early and reduce the likelihood that avoidable problems move further into the delivery pipeline.

## Source Code Security Analysis

GitHub CodeQL is configured for:

- Python
- JavaScript

The workflow runs on:

- Pull requests into `main`
- Pushes to `main`
- A weekly scheduled scan

CodeQL results are surfaced through GitHub code scanning and pull-request checks.

This provides an additional SAST layer beyond the local Bandit checks.

## Dependency Maintenance

Dependabot is configured for:

- Python dependencies
- npm dependencies
- GitHub Actions

Checks run weekly, with minor and patch updates grouped to reduce unnecessary update noise.

Dependabot supports ongoing dependency maintenance and helps reduce exposure to outdated or vulnerable packages.

## Build-Time Security Checks

AWS CodeBuild installs and runs Bandit against the application before packaging the deployment artifact.

The current build command uses:

`bandit -r app -ll || true`

This means findings are reported but do not currently fail the build.

In a production implementation, I would define explicit blocking criteria based on factors such as:

- Severity
- Confidence
- Application criticality
- Exploitability
- Compensating controls
- Approved exception process

Not every finding should necessarily block a release, but the decision should be intentional and policy-driven.

## Deployment Validation

AWS CodeDeploy lifecycle hooks are used to control application installation, startup, and validation.

The implemented sequence is:

`BeforeInstall → AfterInstall → ApplicationStart → ValidateService`

The `ValidateService` hook performs a local HTTP health check against the application on port 8080.

A failed validation causes the deployment validation step to fail.

## Branch and Promotion Controls

The repository uses protected-branch behavior for `main`, requiring changes to move through the pull-request process rather than direct modification.

This supports:

- Review before merge
- Required security checks
- Traceability of changes
- Controlled promotion

Repository-level branch protection settings should remain aligned with the security and release policy.

## Secrets Protection

The implemented secret-control layer includes `detect-secrets` in the pre-commit workflow.

For a production repository, I would also evaluate:

- GitHub secret scanning
- Push protection
- Centralized secrets management
- Short-lived credentials
- Removal of long-lived static credentials from CI/CD
- Rotation and incident procedures for exposed secrets

## CI/CD Identity

The intended production design uses least-privilege CI/CD identities.

Where AWS access is required from GitHub Actions, I would prefer federation such as OIDC rather than long-lived AWS access keys.

Permissions should be scoped to the specific actions required by the workflow.

## Runtime Security Design

The repository does not represent a fully deployed production runtime environment.

A production implementation would evaluate controls such as:

- HTTPS-only access
- TLS certificate management
- Load balancer security controls
- WAF where justified by application risk
- Security groups and network segmentation
- Runtime logging
- Centralized monitoring
- CloudWatch alarms
- IAM least privilege
- Secrets management
- Patch and vulnerability management

These controls should be selected based on the application's exposure, business criticality, regulatory requirements, and threat model.

## Auditability and Change Governance

The architecture supports traceable delivery through:

- Pull requests
- Code scanning results
- Dependency update history
- Build logs
- Deployment lifecycle events
- Version-controlled infrastructure definitions

For production use, I would also define:

- Approval requirements
- Exception handling
- Evidence retention
- Change-management integration
- Incident escalation
- Separation of duties where required

## Production Security Boundary

This project demonstrates selected security and deployment controls, but it is not presented as a complete production security architecture.

Before production adoption, I would validate:

- Identity and access design
- Network exposure
- Secrets handling
- Logging and monitoring
- Runtime protection
- Security gate thresholds
- Rollback conditions
- Dependency and supply-chain controls
- Compliance requirements
- Evidence and retention requirements
- Incident response integration

The goal is to apply controls according to business risk and release requirements rather than treating every available security control as mandatory.
