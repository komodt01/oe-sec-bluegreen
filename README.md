# 🧩 Operational Excellence + Security (Blue/Green Deployment Reference)

This repository demonstrates an **Operational Excellence + Security alignment** based on AWS Well-Architected Framework best practices.  
It focuses on secure, resilient deployment workflows (e.g., Blue/Green) using GitHub Actions and IaC-based guardrails.

> ⚠️ **Important:**  
> This repository reflects **AWS-recommended practices**, not necessarily what should be implemented in every business context.  
> Final architecture and control selection depend on specific business requirements, compliance mandates, and cloud strategy.

---

## 📘 Project Overview

**Purpose:**  
To provide a reference implementation that combines **operational excellence** (deployment reliability, automation, rollback safety) and **security** (integrity, least privilege, supply-chain defense) through GitHub automation and AWS design principles.

**Focus Areas:**
1. Reliable deployments (Blue/Green and CI/CD best practices)
2. Secure code workflows (branch protection, signed commits)
3. Automated static analysis (CodeQL)
4. Automated dependency updates (Dependabot)
5. Immutable release governance (tag protection)
6. Reference alignment with AWS Well-Architected “Operational Excellence” and “Security” pillars

---

## 🏗️ Architecture Summary

**AWS Components (referenced):**
- **Elastic Beanstalk / CodeDeploy** for Blue/Green orchestration  
- **CloudWatch & CloudTrail** for operational logging  
- **IAM Roles + Scoped Policies** for least privilege  
- **AWS Config & Trusted Advisor** for operational insights  
- **S3 versioning & encryption** for artifact storage  
- **KMS (Key Management Service)** for secrets and signing  
- **CloudFormation / Terraform** for repeatable, auditable deployment

**GitHub Components:**
- **Branch protection** on `main` and release branches  
- **CodeQL** scanning for every PR and scheduled run  
- **Dependabot** for dependency vulnerability alerts  
- **Tag protection** enforcing signed, immutable release tags  
- **GitHub Actions** for automated testing and deployment triggers  

---

## 🛡️ Security Posture

This repository is configured to reflect **AWS and GitHub security best practices** for secure software delivery pipelines.  
All configurations are baseline controls intended for demonstration and adaptation.

### Why These Controls Exist

| Control Area | Purpose | Security Benefit |
|---------------|----------|------------------|
| **Branch Protection (main, release/\*)** | Prevents force pushes, unauthorized merges, and accidental history rewrites. | Protects code integrity and enables traceable change control. |
| **Pull Request Reviews** | Requires at least one review before merging. | Ensures peer review and accountability for code changes. |
| **Status Checks (CI, CodeQL)** | Blocks merges until tests and scans pass. | Prevents known issues or vulnerabilities from entering production. |
| **CodeQL Scanning** | Performs static analysis on code paths in PRs and `main`. | Detects injection flaws, unsafe API use, and insecure logic. |
| **Dependabot Alerts and Updates** | Automates dependency patching and version updates. | Keeps dependencies current, minimizing exposure to CVEs. |
| **Tag Protection (v\*)** | Restricts creation, updates, and deletions of release tags. | Guarantees immutability and authenticity of versioned releases. |
| **Signed Commits and Tags** | Requires verified authorship for contributions. | Prevents impersonation and ensures non-repudiation. |

### Summary

This setup provides:
- **Integrity:** Only verified and reviewed code can reach main or release branches.  
- **Traceability:** Each commit and tag is signed, reviewed, and logged.  
- **Supply Chain Security:** Automated scanning and dependency patching reduce risk exposure.  
- **Immutability:** Release artifacts are protected from modification or overwrite.  

> **Disclaimer:**  
> These configurations form a secure baseline aligned to AWS Well-Architected and GitHub security guidelines.  
> Actual enterprise implementation should map to **business requirements, compliance mandates (NIST, ISO 27001, PCI-DSS, SOC2)**, and organizational risk appetite.

---

## ⚙️ Repository Automation Summary

| Tool | Function | Location |
|------|-----------|-----------|
| **CodeQL** | Static analysis on push/PR | `.github/workflows/codeql.yml` |
| **Dependabot** | Dependency scanning + updates | `.github/dependabot.yml` |
| **Branch Protection** | Prevents force-pushes, enforces reviews | Repo Settings → Rules → Branches |
| **Tag Protection** | Locks version tags (v\*) | Repo Settings → Rules → Tags |
| **Signed Commits** | Enforced via GPG or S/MIME signing | Developer local Git config |
| **Workflow Security** | Limits write permissions to GITHUB_TOKEN | `.github/workflows/*` |

---

## 🧱 Repository Structure

```bash
├── .github/
│   ├── workflows/
│   │   ├── codeql.yml
│   │   └── dependabot.yml
│   ├── CODEOWNERS
│   └── SECURITY.md
├── docs/
│   ├── architecture-diagram.png
│   └── wellarchitected-summary.md
├── terraform/                  # optional infrastructure baseline
├── README.md                   # project overview & security posture
└── LICENSE


