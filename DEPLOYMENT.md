# Deployment Architecture — Blue/Green with Security Guardrails

## Purpose

This project demonstrates deployment lifecycle controls that support a blue/green release pattern.

The implemented portion focuses on AWS CodeDeploy lifecycle hooks, application startup, deployment validation, secrets detection, and controlled repository changes.

The full production runtime architecture — including separate Blue and Green capacity, Application Load Balancer target groups, traffic switching, CloudWatch alarm integration, and automated rollback — is represented as an architecture scaffold rather than a completed deployment.

## Deployment Flow

The intended blue/green flow is:

1. **Blue** continues serving the current production version.
2. **Green** receives the candidate application release.
3. AWS CodeDeploy lifecycle hooks prepare and start the candidate application.
4. The candidate release is health-checked before traffic promotion.
5. In a production implementation, Green would be registered with a separate load balancer target group.
6. Additional operational, security, and functional criteria would be evaluated.
7. Traffic would move to Green only after the required criteria pass.
8. Blue would remain available during a defined rollback window.

The reason I chose this pattern is to avoid modifying the environment currently serving users while a candidate release is being introduced and evaluated.

## Implemented Deployment Controls

### CodeDeploy Lifecycle Hooks

The repository includes an `appspec.yml` that defines the following lifecycle sequence:

`BeforeInstall → AfterInstall → ApplicationStart → ValidateService`

Supporting shell scripts provide the deployment lifecycle structure for preparation, installation, startup, and validation.

### Application Health Validation

The `ValidateService` hook performs a local HTTP health check against:

`http://127.0.0.1:8080`

The health-check script uses `curl` with failure handling, so an unsuccessful HTTP response causes the validation script to fail.

This verifies that the service is responding locally after startup.

It does not establish that all application dependencies, integrations, or business functions are healthy.

### Repository Controls

The deployment lifecycle is supported by repository controls including:

- `detect-secrets` pre-commit checking
- Dependabot maintenance for GitHub Actions
- Pull-request-based changes to the protected `main` branch

These controls address different risks and should not be treated as substitutes for application-specific security testing or production deployment validation.

## Production Blue/Green Design

A production implementation would extend the current deployment lifecycle with:

- Separate Blue and Green application capacity
- Application Load Balancer
- Separate Blue and Green target groups
- Load balancer health checks
- Controlled traffic promotion
- CloudWatch monitoring and alarms
- Automated rollback where appropriate
- Retention of the previous environment during a defined rollback window

The amount of parallel capacity and the length of the rollback window would depend on availability objectives, deployment frequency, recovery requirements, operational risk, and infrastructure cost.

## Traffic Promotion

Successful deployment should not automatically authorize production traffic.

For a production workload, I would define promotion criteria based on signals such as:

- CodeDeploy lifecycle status
- Application response
- Load balancer target health
- Error rate
- Latency
- Critical dependency availability
- Application-specific functional validation
- Security telemetry
- Required approvals

The exact criteria should be tied to what the application needs to do for the business.

For higher-risk applications, I would also evaluate gradual traffic shifting rather than an immediate full cutover.

## Rollback

The purpose of retaining Blue is to provide a known-good recovery environment while Green is introduced.

A production rollback could be triggered when:

- Green fails deployment validation
- Application health checks fail
- Error rates exceed defined thresholds
- Latency degrades materially
- Critical dependencies become unavailable
- Functional validation fails
- Security monitoring identifies unacceptable behavior

If failure occurs before traffic promotion, Blue should continue serving users.

If failure occurs after promotion, traffic could be redirected to Blue while the candidate release is investigated.

The decision to automate rollback would depend on whether the triggering condition is reliable enough to justify immediate action without human intervention.

## Infrastructure Scaffold

The repository contains an AWS CDK architecture scaffold describing the intended blue/green infrastructure.

The full runtime environment was not deployed as part of this project.

In a completed implementation, the infrastructure definition would include the load balancer, target groups, compute capacity, CodeDeploy deployment group, monitoring, alarms, and rollback configuration.

Infrastructure changes would be reviewed before deployment, with production approval requirements determined by the organization's change-management process.

## Production Considerations

Before implementing this pattern for a production workload, I would evaluate:

- Business criticality and availability requirements
- Recovery objectives
- Acceptable deployment and rollback windows
- IAM and deployment identities
- Network segmentation
- TLS and certificate management
- Secrets management
- Application and dependency health criteria
- Monitoring and alert thresholds
- Data and schema compatibility between releases
- Infrastructure capacity and cost
- Manual versus automated rollback
- Change approval and exception processes

Blue/green deployment reduces some forms of release risk, but it does not remove the need to understand the application's dependencies, failure modes, and business impact.
