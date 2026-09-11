# Deployment (Blue/Green)

# Deployment Architecture — Blue/Green with Security Guardrails

## Purpose

This project demonstrates the deployment lifecycle and security controls that support a blue/green release pattern.

The implemented portion focuses on secure promotion, deployment hooks, application startup, and health validation.

The full production runtime architecture — including separate Blue and Green capacity, Application Load Balancer target groups, traffic switching, CloudWatch alarm integration, and automated rollback — is represented as an architecture scaffold rather than a completed deployment.

## Deployment Flow

The intended blue/green flow is:

1. **Blue** continues serving the current production version.
2. **Green** receives the candidate application release.
3. Security and quality checks run before promotion.
4. AWS CodeDeploy lifecycle hooks install and start the candidate application.
5. The candidate is validated before traffic promotion.
6. In a production implementation, Green would be registered with a separate load balancer target group.
7. Traffic would move to Green only after defined health and release criteria pass.
8. Blue would remain available during a rollback window.

This separation reduces the risk of modifying the environment currently serving users.

## Implemented Deployment Controls

### CodeDeploy Lifecycle Hooks

The repository includes an `appspec.yml` that defines the following lifecycle sequence:

`BeforeInstall → AfterInstall → ApplicationStart → ValidateService`

Supporting scripts handle deployment preparation, installation, startup, and health validation.

### Application Health Validation

The `ValidateService` hook performs a local HTTP health check against:

`http://127.0.0.1:8080`

The health-check script uses `curl` with failure handling so an unsuccessful HTTP response causes deployment validation to fail.

This confirms that the application started successfully and is responding locally.

It does not prove that all application dependencies or business functions are healthy.

## Security and Quality Gates

The deployment lifecycle is supported by controls earlier in the delivery process:

- Pre-commit Bandit scanning
- detect-secrets
- Ruff and Black quality checks
- GitHub CodeQL analysis
- Dependabot dependency maintenance
- Build-time Bandit scanning

The current CodeBuild configuration records Bandit findings but does not fail the build because the command uses `|| true`.

For a production implementation, I would define explicit promotion rules that determine which findings:

- Block the release
- Require remediation
- Require a documented exception
- Generate an alert without blocking

Those thresholds should reflect application criticality, vulnerability severity and confidence, business risk, and organizational policy.

## Production Blue/Green Design

A production implementation would extend the current deployment lifecycle with:

- Separate Blue and Green application capacity
- Application Load Balancer
- Separate target groups
- Health checks at the load balancer level
- Controlled traffic promotion
- CloudWatch alarms
- Automated rollback
- Retention of the previous environment during the rollback window

The amount of parallel capacity and length of the rollback window should be based on availability objectives, deployment frequency, operational risk, and infrastructure cost.

## Traffic Promotion

Traffic should not be moved to Green solely because deployment completed successfully.

Promotion should depend on defined release criteria such as:

- Application health
- Load balancer target health
- Error rate
- Latency
- Critical dependency availability
- Security findings
- Functional validation
- Required approvals

For higher-risk applications, promotion could be gradual rather than an immediate full cutover.

## Rollback

The purpose of retaining Blue is to provide a known-good recovery path.

A production rollback could be triggered when:

- Green fails deployment validation
- Application health checks fail
- Error rates exceed defined thresholds
- Latency degrades materially
- Critical dependencies fail
- Security monitoring identifies unacceptable behavior

If failure occurs before traffic promotion, Blue should continue serving users.

If failure occurs after promotion, traffic should be redirected back to Blue while the failed release is investigated.

## Infrastructure Deployment

The repository contains an AWS CDK scaffold for the blue/green architecture.

For non-production experimentation, infrastructure changes can be synthesized and reviewed with:

```bash
cdk synth
