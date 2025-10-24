# Security

- Least privilege for CI roles (OIDC→AWS).
- Signed commits, required PR reviews.
- Secret scanning and `detect-secrets` pre-commit.
- Runtime: WAF (optional), HTTPS only, logging enabled.
- Compliance mapping: change sets (CloudFormation), traceable releases.
