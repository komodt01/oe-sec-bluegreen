# Technical Case Study — Blue/Green Deployment Security Architecture

## Technical Problem

The technical problem was to design a deployment process where a candidate application release could be introduced and validated without immediately modifying the environment serving production traffic.

For this prototype, I focused on the deployment lifecycle and failure behavior rather than building the entire production AWS environment.

The implemented portion uses AWS CodeDeploy lifecycle hooks and shell scripts to prepare the deployment location, install the candidate release, start a demonstration service, and validate that the service responds successfully.

The broader architecture extends this process into a production blue/green model using separate Blue and Green capacity, an Application Load Balancer with separate target groups, defined promotion criteria, monitoring, and rollback.

One important design principle is that **deployment success and production promotion are separate decisions**. Successfully copying files and starting a process does not by itself prove that a release is ready to receive production traffic.

## Architecture and Deployment Flow

The target architecture separates the currently active production environment, Blue, from the candidate environment, Green.

### 1. Blue Serves Production Traffic

Blue represents the known-good application version and continues serving users while the candidate release is prepared.

### 2. Green Receives the Candidate Release

AWS CodeDeploy coordinates the deployment lifecycle. The repository's `appspec.yml` defines the sequence:

`BeforeInstall → AfterInstall → ApplicationStart → ValidateService`

### 3. BeforeInstall Prepares the Destination

`before_install.sh` creates `/opt/oe-app` if it does not already exist.

Script execution uses strict error handling so an unexpected failure stops the lifecycle step.

### 4. AfterInstall Installs the Release

`after_install.sh` copies the deployment contents into `/opt/oe-app`.

The installation step is configured to fail if the copy operation fails rather than allowing deployment to continue with an incomplete installation.

### 5. ApplicationStart Starts the Candidate Service

`start.sh` stops an existing demonstration HTTP server if one exists and starts the candidate service on port `8080`.

The absence of an existing process is an acceptable condition, so that specific stop operation is allowed to continue without failing the deployment.

### 6. ValidateService Tests the Candidate

`health_check.sh` sends an HTTP request to:

`http://127.0.0.1:8080`

An unsuccessful response causes the validation script to fail. This prevents an application that cannot successfully respond after startup from being treated as a valid deployment.

### 7. Production Promotion Occurs Separately

In the target production architecture, Green would be associated with its own load balancer target group.

Additional application, dependency, operational, and security signals would be evaluated before production traffic is moved from Blue to Green.

### 8. Blue Remains Available for Rollback

Blue would remain intact for a defined period after promotion.

If Green violates defined post-cutover criteria, traffic could be redirected to the known-good Blue environment.

## Implemented Controls vs. Target Production Architecture

I intentionally separate what was implemented in the prototype from what would be required for a production blue/green environment.

### Implemented in the Prototype

**CodeDeploy lifecycle control**

`appspec.yml` defines the order in which deployment activities occur. A release does not simply copy files and assume success; preparation, installation, startup, and validation occur as separate lifecycle stages.

**Fail-on-installation-error behavior**

The installation script fails when deployment content cannot be copied successfully. An incomplete installation should not proceed to application startup.

**Application startup control**

The startup script handles the possibility that an earlier demonstration process may or may not already exist before starting the candidate service.

**Health validation**

`ValidateService` confirms that the candidate responds successfully over HTTP on port `8080`. Failure stops validation.

**Secrets detection**

`detect-secrets` provides a pre-commit control intended to identify potential credentials before they enter source control.

**Workflow dependency maintenance**

Dependabot checks GitHub Actions dependencies on a weekly schedule.

**Controlled repository changes**

Changes to the protected `main` branch move through the pull-request workflow rather than direct modification.

### Target Production Architecture

The complete blue/green runtime was not deployed as part of this prototype.

For production, I would extend the implemented lifecycle with:

- Separate Blue and Green compute capacity
- Application Load Balancer
- Separate target groups
- Load balancer health checks
- Controlled or gradual traffic shifting
- CloudWatch metrics and alarms
- Application and dependency health signals
- Security telemetry
- Automated rollback for appropriate failure conditions
- Defined post-deployment observation period
- Least-privilege deployment identities
- TLS, network segmentation, and secrets management

The exact implementation would depend on the application's availability requirements, architecture, dependencies, business criticality, and recovery objectives.

## Failure Paths and Rollback Behavior

A blue/green architecture is useful only if failure behavior is defined before the release occurs.

### Installation Failure

If `BeforeInstall` cannot prepare the destination or `AfterInstall` cannot copy the deployment contents successfully, the CodeDeploy lifecycle should fail.

The candidate should not proceed to startup because the integrity of the installation cannot be assumed.

**Result:** Green fails deployment. Blue remains unchanged and continues serving production traffic.

### Application Startup Failure

If the candidate application cannot start successfully, the deployment should not be eligible for traffic promotion.

The prototype uses a demonstration HTTP service, but a production implementation would also capture application logs and startup telemetry to support diagnosis.

**Result:** Green is not promoted. Blue remains active.

### Health Validation Failure

`ValidateService` checks the candidate service on port `8080`. If the HTTP request fails, the lifecycle validation fails.

A production health check would go beyond process availability and evaluate whether the application can perform the functions required to safely receive traffic.

**Result:** Green is not promoted.

### Failure During Traffic Promotion

In the production design, Green could pass initial validation but begin exhibiting problems as real traffic is introduced.

I would monitor signals such as target health, error rate, latency, dependency failures, application-specific transactions, and security telemetry during the promotion period.

For higher-risk workloads, I would consider gradual traffic shifting so that Green receives only a portion of traffic before full cutover.

**Result:** Promotion can be stopped or reversed when defined thresholds are exceeded.

### Failure After Cutover

Blue should remain available for a defined observation period after Green becomes active.

If Green violates agreed operational or security thresholds during that period, traffic can be returned to Blue while the candidate release is investigated.

Automated rollback makes sense when the triggering signal is reliable and immediate action is preferable to waiting for human intervention. Ambiguous conditions may require alerting and operational judgment instead.

### Data Compatibility Failure

Application rollback does not automatically mean data rollback.

If Green introduces database or schema changes that are incompatible with Blue, simply redirecting traffic to Blue may not restore service successfully.

For a production design, I would therefore evaluate backward-compatible schema changes, migration sequencing, data rollback requirements, and dependency compatibility as part of the release architecture.

## Health, Promotion, and Monitoring Criteria

The implemented health check answers a narrow question: **did the candidate service start and respond successfully on port 8080?**

That is appropriate for demonstrating the deployment lifecycle, but it would not be sufficient for a production promotion decision.

### Production Health Criteria

For a production application, I would evaluate multiple signals before Green receives full production traffic:

- **Infrastructure health** — compute capacity and ALB target health
- **Application availability** — expected application endpoints respond successfully
- **Error rate** — failures remain within an acceptable threshold
- **Latency** — response times remain within the application's service objectives
- **Dependency health** — required databases, APIs, queues, identity services, or other dependencies are reachable and functioning
- **Functional validation** — critical business transactions complete successfully
- **Security telemetry** — the candidate does not introduce unexpected security events or behavior

### Promotion Decision

I would treat traffic promotion as a controlled decision rather than an automatic consequence of successful deployment.

For a lower-risk workload, passing the required health checks may be sufficient for automated promotion.

For a higher-impact workload, I would consider additional approval or a staged traffic shift, for example:

`Blue 100% / Green 0% → Blue 90% / Green 10% → Blue 50% / Green 50% → Green 100%`

The actual percentages and observation periods would be determined by application traffic patterns, business impact, and recovery requirements rather than using fixed values for every workload.

### Monitoring After Promotion

Monitoring should continue after Green receives production traffic because some problems will only appear under real workload conditions.

CloudWatch metrics and alarms could monitor application errors, latency, target health, infrastructure health, and other application-specific signals.

The previous Blue environment would remain available during a defined observation window. Once Green demonstrates sustained stability and the rollback window expires, Blue capacity could be retired or prepared for the next deployment cycle.

## Identity, Security, and Deployment Trust Boundaries

The deployment process introduces several trust boundaries. A production architecture should make those boundaries explicit rather than treating the deployment pipeline as inherently trusted.

### Source Control

Developers propose changes through the repository's pull-request process. The protected `main` branch provides a control point between proposed changes and accepted changes.

This creates a basic separation between **code that is being developed** and **code that is eligible for deployment**.

### Deployment Identity

AWS CodeDeploy requires an identity with permission to perform the deployment activities assigned to it.

For production, I would apply least privilege to the deployment roles and limit permissions to the resources and actions required for the specific deployment.

If an external CI/CD platform such as GitHub Actions needs AWS access, I would prefer short-lived federated credentials such as OIDC rather than long-lived access keys.

### Compute Environment

The deployment process crosses into the application environment when CodeDeploy executes the lifecycle hooks.

The scripts therefore represent a security boundary and should be treated as deployment code rather than ordinary application utilities.

In production, I would restrict who can modify those scripts, control the identity under which they execute, and ensure the target compute environment is appropriately hardened.

### Secrets

Secrets should not be embedded in the deployment scripts or application artifacts.

The implemented `detect-secrets` pre-commit control provides an early opportunity to identify potential secrets before they enter source control.

Production deployments would additionally require an appropriate secrets-management mechanism and controlled access to those secrets.

### Network and Traffic Boundary

The prototype validates the service locally on `127.0.0.1:8080`. That is intentionally narrower than a production traffic test.

In the target architecture, the Application Load Balancer becomes the controlled entry point between users and the application environments. Security groups, TLS, target-group health checks, and other network controls would be evaluated at that boundary.

This also reinforces an important distinction: **a local health check proves local service availability; it does not prove that the application is safely reachable or functional through the production traffic path.**

### Trust Decision

The overall deployment trust model should therefore progress through several decisions:

`Code change → Review → Deployment → Candidate validation → Traffic promotion → Post-cutover monitoring`

Each stage provides an opportunity to stop or redirect the release before the change creates unacceptable business impact.

## Observability, Evidence, and Operational Response

Deployment safety depends on being able to determine whether a release is behaving as expected and to provide evidence for the deployment decision.

### Implemented Evidence

The prototype provides evidence at the deployment lifecycle level through:

- CodeDeploy lifecycle execution
- Script success or failure
- Application startup behavior
- `ValidateService` health-check results
- Pull-request and repository history
- Version-controlled deployment configuration

The local health check provides a simple pass/fail signal that the candidate service responds on port 8080.

### Production Observability

A production implementation would extend this with centralized monitoring and application telemetry.

I would evaluate:

- ALB target health
- Application error rates
- Response latency
- Request volume
- Infrastructure health
- Critical dependency failures
- Application logs
- Security events

CloudWatch alarms could then provide automated signals for conditions that require stopping promotion, initiating rollback, or escalating to operations.

### Evidence for Promotion

The promotion decision should be traceable.

For each release, I would want to be able to determine:

- What version was deployed
- When deployment occurred
- Which environment received the candidate
- Which validation checks passed or failed
- What monitoring criteria were evaluated
- Whether traffic was promoted
- Whether rollback occurred
- Who approved or authorized the change where approval is required

This creates a useful connection between **technical deployment evidence and operational accountability**.

### Incident Response

If Green fails after receiving production traffic, monitoring should generate an actionable signal rather than simply recording that the application is unhealthy.

The response path would be:

`Detect → Assess → Stop/rollback → Stabilize → Investigate → Remediate → Validate`

The appropriate response would depend on the severity and reliability of the signal. An automatic rollback is useful when the failure condition is well understood; ambiguous conditions may require human investigation before taking action.

### Operational Principle

The goal is not to collect every possible metric. The goal is to collect the signals necessary to determine whether the release is safe to promote, whether it remains healthy after promotion, and when intervention is required.

## Production Architecture and AWS Component Mapping

The production architecture extends the implemented CodeDeploy lifecycle into a complete blue/green deployment model. The components below represent the intended production design rather than components that were fully deployed in this prototype.

| Component | Role | Architectural Purpose |
|---|---|---|
| **Blue environment** | Current release | Maintains the known-good application version while Green is evaluated. |
| **Green environment** | Candidate release | Hosts the new version separately from the active environment. |
| **EC2 / Auto Scaling Group** | Application compute | Provides capacity for the Blue and Green environments and supports replacement or scaling of instances. |
| **Application Load Balancer** | Traffic entry point | Provides the controlled path for application traffic and supports health-based target evaluation. |
| **Target groups** | Traffic routing | Separates Blue and Green destinations so traffic can be shifted between environments. |
| **AWS CodeDeploy** | Deployment orchestration | Coordinates the deployment lifecycle and executes the application deployment hooks. |
| **CodeDeploy lifecycle hooks** | Deployment controls | Provides defined points for installation, startup, and validation. |
| **CloudWatch** | Monitoring and alarms | Provides operational signals that can support promotion, alerting, or rollback decisions. |
| **AWS CDK** | Infrastructure definition | Provides the infrastructure-as-code structure for the intended blue/green environment. |

### End-to-End Production Flow

```text
Developer change
      ↓
Pull request / review
      ↓
Approved release
      ↓
CodeDeploy
      ↓
Green environment
      ↓
Lifecycle hooks
      ↓
Application startup
      ↓
Health + functional validation
      ↓
Promotion criteria
      ↓
Traffic shift
      ↓
Green serves production
      ↓
Post-cutover monitoring
      ↓
Rollback if required
```

Blue remains available during the defined rollback window.

### Architectural Boundary

The important distinction is that the repository **implements the CodeDeploy deployment lifecycle and local health validation**, while the ALB, separate target groups, parallel compute capacity, production monitoring, and automated traffic rollback represent the target architecture.

That distinction is intentional. The prototype demonstrates the control flow without claiming that a complete production AWS environment was deployed.

### Why These Components Work Together

The individual AWS services are less important than the control relationship between them.

**CodeDeploy** controls *how the release is introduced*.

**The health checks and monitoring** determine *whether the candidate is behaving acceptably*.

**The ALB and target groups** provide the mechanism to control *where production traffic goes*.

**Blue** provides the known-good recovery environment.

**CloudWatch alarms and defined promotion criteria** provide the signals needed to determine *when to continue, stop, or reverse the release*.

That separation is what turns a basic deployment process into a controlled blue/green architecture.

## Security Controls and Threat Considerations

The security objective is to ensure that deployment automation does not become a path for an unvalidated or unauthorized change to reach production.

### Primary Threats

| Threat | Potential Impact | Primary Control |
|---|---|---|
| Unauthorized code change | Malicious or unapproved release reaches production | Protected `main`, pull-request review |
| Secret committed to repository | Credential exposure or unauthorized access | `detect-secrets` pre-commit control |
| Compromised deployment script | Attacker alters deployment behavior | Repository protection, review, version control |
| Incomplete deployment | Candidate environment operates with missing files or configuration | CodeDeploy lifecycle failure handling |
| Failed application startup | Invalid candidate reaches promotion stage | `ApplicationStart` / `ValidateService` |
| Unhealthy candidate promoted | Customer impact or outage | Health and promotion criteria |
| Post-cutover degradation | Production service becomes unstable | Monitoring, alarms, rollback |
| Rollback incompatibility | Returning to Blue does not restore service | Backward-compatible data/schema strategy |

### Security Control Positioning

The controls operate at different points in the deployment process:

```text
Source Change
     ↓
Pull Request / Review
     ↓
Secrets Detection
     ↓
Deployment
     ↓
Installation Validation
     ↓
Application Startup
     ↓
Health Validation
     ↓
Production Promotion
     ↓
Monitoring
     ↓
Rollback if required
```

No single control provides complete protection. The objective is to create multiple opportunities to identify or stop an unsafe change.

### Deployment Trust

The CodeDeploy lifecycle scripts should be treated as **deployment infrastructure**, not simply application support scripts.

For production, I would restrict who can modify them and ensure the deployment identity has only the permissions necessary to perform the deployment.

If an external CI/CD platform is used to initiate AWS deployments, I would prefer short-lived federated credentials such as OIDC rather than long-lived access keys.

### Candidate Environment Isolation

The production design separates Green from the environment currently serving users.

This provides an additional boundary where the candidate can be evaluated before receiving production traffic.

The separation does not eliminate risk. A compromised or defective release can still become production if the promotion controls are insufficient. Therefore, promotion criteria and monitoring remain important security and operational controls.

### Rollback as a Security Control

Rollback is primarily an availability and operational mechanism, but it can also reduce security exposure.

For example, if a newly deployed release introduces an unexpected security behavior, returning traffic to the known-good version can provide a rapid containment option while the release is investigated.

Rollback should not be treated as a substitute for fixing the underlying vulnerability.

### Threat Modeling Boundary

This prototype does not include a completed formal threat model or risk register.

For a production implementation, I would conduct a threat assessment based on the actual application, deployment architecture, trust boundaries, identities, data flows, external exposure, and business impact.

The controls and monitoring requirements would then be prioritized according to the resulting risk rather than applying a generic checklist.

## Technical Decisions, Tradeoffs, and Lessons Learned

The project reinforced that deployment architecture is not just about selecting a deployment service. The important decisions are how the release is validated, when traffic is allowed to move, what constitutes failure, and how the organization recovers.

### 1. Separate Deployment from Promotion

A key design decision is to treat **deployment and production promotion as separate steps**.

Installing the application successfully does not mean the release is ready for users. The candidate should first pass the required validation criteria.

This creates a deliberate control point between **“the software is deployed”** and **“the software is serving production traffic.”**

### 2. Fail When Required Deployment Steps Fail

The deployment scripts use strict shell behavior:

```bash
set -euo pipefail
```

The installation step was also changed so that a failed copy operation is not masked.

That distinction is important. A deployment should fail when a required operation fails.

Conversely, the startup script intentionally allows the process-stop command to succeed when there is no existing process to stop. That is an expected condition rather than a deployment failure.

### 3. Keep Health Validation Simple but Honest

The implemented health check tests whether the demonstration service responds successfully on port 8080.

I would not represent that as a complete production health check.

In a real environment, the validation would need to reflect the application's actual business function and dependencies. This could include functional transactions, dependency checks, latency, error rates, and other operational signals.

### 4. Blue/Green Has a Real Cost

The primary benefit is a safer recovery path, but that benefit comes with additional infrastructure and operational complexity.

Maintaining two environments can increase:

- Infrastructure cost
- Deployment complexity
- Monitoring requirements
- Configuration management
- Data compatibility concerns

The pattern therefore needs to be justified by business risk rather than treated as the default deployment strategy.

### 5. Rollback Is Not Always Simple

One of the most important architectural considerations is the data layer.

Returning traffic to Blue may not be sufficient if Green has already introduced an incompatible database schema or data change.

A production implementation would therefore need to consider backward-compatible database changes, migration sequencing, dependency compatibility, and whether application rollback and data rollback can actually be separated.

### 6. Security Controls Should Support the Deployment Decision

Security should not simply produce a collection of scans.

The useful question is:

> **What information does the organization need to decide whether this release should proceed?**

That means security findings, operational health, application behavior, and business risk may all contribute to the promotion decision.

The appropriate controls and blocking thresholds should be determined by application criticality and organizational policy.

## Lessons Learned

The project evolved as I reviewed the original implementation.

The original repository contained several security and development controls that were not supported by meaningful application source code. Rather than leaving those controls in place simply because they appeared comprehensive, I removed them and narrowed the project to controls that actually support the architecture.

That review reinforced an important architectural principle:

**A smaller, accurate control set is more valuable than a larger collection of controls that cannot be demonstrated or justified.**

The resulting project is intentionally bounded. It demonstrates the deployment lifecycle and documents the production architecture without claiming to be a complete production platform.

## Scope, Evidence, and Production Gap

This project demonstrates a **deployment security architecture pattern**, not a complete production implementation.

The evidence in the repository supports the following implemented capabilities:

- AWS CodeDeploy deployment lifecycle
- Pre-installation preparation
- Deployment file installation
- Application startup
- Local service health validation
- Failure handling within the deployment scripts
- Pre-commit secret detection
- GitHub Actions dependency maintenance
- Protected repository change flow
- Documented Blue/Green production architecture

The repository also contains the architectural scaffold for the production environment, including the intended use of separate Blue and Green capacity, load balancing, controlled traffic promotion, monitoring, and rollback.

### What Would Be Required for Production

Before using this pattern for a real application, I would need to validate:

- Application and business criticality
- Availability and recovery objectives
- Network and security architecture
- IAM and deployment identities
- ALB and target-group configuration
- Application-specific health criteria
- Dependency and data compatibility
- Monitoring and alarm thresholds
- Traffic-shifting strategy
- Automated versus manual rollback
- Secrets management
- Change approval and exception processes
- Operational ownership and incident response

The production architecture should be designed from those requirements rather than assuming that the prototype's settings are appropriate for every workload.

## Final Architectural Position

The resulting architecture can be summarized as:

```text
Known-Good Blue
       │
       │ remains available
       │
       ▼
Candidate Green
       │
       ├── Deploy
       ├── Start
       ├── Validate
       ├── Monitor
       │
       ▼
Promotion Decision
       │
       ├── Pass ──► Traffic → Green
       │
       └── Fail ─► Remain/Return → Blue
```

The architectural objective is straightforward:

**Introduce change without unnecessarily putting the known-good environment at risk, and establish a defined recovery path when the change does not behave as expected.**

The specific AWS services are implementation choices around that objective.

## Technical Takeaway

The primary lesson from this project is that **deployment is a security and operational decision, not simply a software installation event**.

A candidate release should be introduced, validated, and monitored before the organization commits production traffic to it. When the risk or business impact justifies the additional infrastructure, blue/green provides a practical way to preserve a known-good environment while that decision is being made.

That is the core architectural value demonstrated by this project.
