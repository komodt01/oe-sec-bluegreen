# Security Controls and Production Considerations

## Purpose

This project demonstrates how security and operational controls can be incorporated into a blue/green deployment process.

The implemented controls focus on secrets detection, dependency maintenance, controlled changes to the repository, CodeDeploy lifecycle hooks, and deployment health validation.

The broader runtime security controls described here represent production design considerations rather than fully deployed components.

## Implemented Security Controls

### Secrets Detection

The repository uses `detect-secrets` as a pre-commit control to identify potential credentials or secrets before changes are committed.

This provides an early control intended to reduce the likelihood of sensitive information entering source control.

For a production repository, I would also evaluate:

- GitHub secret scanning and push protection
- Centralized secrets management
- Short-lived credentials
- Credential rotation
- Incident procedures for exposed secrets

## Dependency and Workflow Maintenance

Dependabot is configured to check GitHub Actions dependencies on a weekly schedule.

Minor and patch updates are grouped to reduce unnecessary update noise while maintaining visibility into workflow dependency changes.

Updates should still move through the repository's normal review and validation process before being merged.

## Deployment Validation

AWS CodeDeploy lifecycle hooks define the deployment sequence:

`BeforeInstall → AfterInstall → ApplicationStart → ValidateService`

The `ValidateService` hook performs a local HTTP health check against the service on port 8080.

If the endpoint does not respond successfully, the validation script fails.

This is intentionally a basic deployment check. For a production workload, successful process startup alone would not necessarily be sufficient to authorize traffic promotion.

Additional validation could include:

- Load balancer target health
- Application error rates
- Latency
- Critical dependency availability
- Application-specific functional checks
- CloudWatch alarms
- Security telemetry

The appropriate checks would depend on what the application does and the business impact of an unsuccessful release.

## Branch and Promotion Controls

The repository uses protected-branch behavior for `main`, requiring changes to move through the pull-request process rather than direct modification.

This supports:

- Review before merge
- Change traceability
- Controlled promotion
- Separation between proposed and accepted changes

In a production environment, branch protection and approval requirements should be aligned with application criticality and organizational change policy.

## CI/CD Identity

A production implementation would use least-privilege identities for deployment automation.

Where GitHub Actions requires access to AWS resources, I would prefer federated authentication such as OIDC rather than storing long-lived AWS access keys.

Permissions should be limited to the resources and actions required by the deployment workflow.

This identity architecture is a production design consideration and is not presented as an implemented control in this repository.

## Blue/Green Security Considerations

The blue/green pattern provides a useful security and operational boundary between the known-good production release and the candidate release.

For this scenario, I would keep Blue available while Green is deployed and validated. Traffic would only be promoted after the required health and release criteria are satisfied.

If Green fails validation or defined post-cutover thresholds, traffic should remain on or return to Blue.

This does not eliminate deployment risk, but it provides a more controlled recovery path than modifying the production environment in place.

## Runtime Security Design

The repository does not represent a fully deployed production runtime environment.

A production implementation would require evaluation of controls such as:

- HTTPS-only access
- TLS certificate management
- Load balancer security
- WAF where justified by application risk
- Security groups and network segmentation
- IAM least privilege
- Secrets management
- Runtime logging and centralized monitoring
- CloudWatch alarms
- Patch and vulnerability management

These controls should be selected based on the application's exposure, business criticality, regulatory requirements, and threat model.

## Auditability and Change Governance

The implemented repository and deployment structure provides several sources of change evidence, including:

- Pull-request history
- Dependency update history
- Version-controlled deployment scripts
- CodeDeploy lifecycle events
- Repository change history

For production use, I would also define:

- Approval requirements
- Security and operational exception handling
- Evidence retention
- Change-management integration
- Incident escalation
- Separation of duties where required

## Production Security Boundary

This project demonstrates selected security and deployment controls within a blue/green architecture prototype. It is not presented as a complete production security architecture.

Before production adoption, I would validate:

- Identity and access design
- Network exposure and segmentation
- Secrets handling
- Logging and monitoring
- Runtime protection
- Health and promotion criteria
- Rollback conditions
- Supply-chain controls
- Compliance requirements
- Evidence and retention requirements
- Incident response integration

The specific controls and thresholds should be driven by the application's business function and risk rather than by applying every available security control by default.
