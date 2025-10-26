## Security Posture: Operational Excellence + Code Security

This repository enforces a hardened DevSecOps posture by combining GitHub Advanced Security, CodeQL analysis, and protected branch workflows to prevent unreviewed or vulnerable code from merging.

### Key Security Controls
- **Branch Protection Rules:** Enforce PR-based reviews, signed commits, and passing CI/CD checks before merge.
- **CodeQL Scanning:** Automatically analyzes JavaScript and Python for known vulnerabilities and coding flaws on each push and pull request.
- **Dependency Management:** Dependabot monitors third-party dependencies and raises alerts for outdated or insecure packages.
- **Rule-Based Merging:** Merges are blocked until all required checks (lint, CI build, CodeQL scanning) complete successfully.
- **Principle of Least Privilege:** Permissions are scoped to `contents: read` and `security-events: write` only.

### Security Outcome
These combined measures ensure:
- Early detection of code-level security defects before deployment.
- Controlled code promotion with enforced review and validation.
- Continuous compliance alignment with OWASP and NIST software assurance principles.

> **Result:** This repository demonstrates an operationally secure CI/CD pipeline integrating automation, least-privilege principles, and continuous vulnerability analysis.
