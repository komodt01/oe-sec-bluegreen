# GitHub Security Automation & Code Scanning Enforcement

This repository demonstrates an end-to-end **security posture for GitHub** using native tooling:
**Branch Protection**, **CodeQL (SAST)**, **linting & formatting**, and **pull-request enforcement** via
**GitHub Actions**. The goal is to ensure only verified, scanned, and policy-compliant code reaches `main`.

---

## Overview

- Continuous CodeQL analysis for **Python** and **JavaScript**
- Branch protection with enforced PRs, signed commits, and required checks
- Linting/formatting/security gates (e.g., ruff, black, bandit) via CI
- Weekly scheduled security scans (cron)
- Clear audit trail for compliance

---

## Components

| Component | Purpose |
| --- | --- |
| CodeQL (GitHub Advanced Security) | Static Application Security Testing (SAST) for Python and JavaScript. |
| Branch Protection Rules | Enforce PRs to `main`, block force pushes/deletions, require signed commits, require passing checks. |
| CI Workflows | Run lint/synth checks and CodeQL on PRs and pushes to `main`. |
| Pre-commit Security | Opinionated checks: ruff/black/bandit to keep code safe and consistent. |

---

## Security Posture

### Branch Protection (recommended)

| Control | Setting (example) |
| --- | --- |
| Require pull request before merging | Enabled |
| Require status checks to pass | `ci / lint-and-synth`, `Code scanning results / CodeQL` |
| Require signed commits | Enabled |
| Block force pushes | Enabled |
| Restrict deletions | Enabled |

### CodeQL Coverage

| Language | Triggers |
| --- | --- |
| Python | Push to `main`, Pull Requests to `main`, Weekly cron scan |
| JavaScript | Push to `main`, Pull Requests to `main`, Weekly cron scan |

---

## Workflow: `.github/workflows/codeql.yml`

```yaml
name: "CodeQL"

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]
  schedule:
    - cron: "0 3 * * 0" # weekly Sunday 03:00 UTC

permissions:
  contents: read
  security-events: write

jobs:
  analyze:
    name: Analyze (${{ matrix.language }})
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        language: [ "python", "javascript" ]

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Initialize CodeQL
        uses: github/codeql-action/init@v3
        with:
          languages: ${{ matrix.language }}

      - name: Autobuild
        uses: github/codeql-action/autobuild@v3

      - name: Perform CodeQL Analysis
        uses: github/codeql-action/analyze@v3
        with:
          category: "/language:${{ matrix.language }}"


