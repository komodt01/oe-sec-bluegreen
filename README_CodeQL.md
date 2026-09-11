# CodeQL Static Application Security Testing (SAST)

## Why It Is Here

This repository uses GitHub CodeQL to identify potentially vulnerable coding patterns before application changes are promoted.

For this project, CodeQL supports two primary objectives:

- **Security** — identify vulnerable or unsafe coding patterns earlier in the delivery lifecycle.
- **Operational Excellence** — make security analysis repeatable through automated pull-request, main-branch, and scheduled scanning.

The architecture decision is the security capability, not the specific product. CodeQL was selected because this project uses GitHub and integrates directly with the repository workflow. In an enterprise environment, the SAST platform would be selected based on application languages, development platform, security requirements, integration needs, cost, and organizational standards.

## What It Scans

Languages enabled in this repository:

- Python
- JavaScript

Go was removed from the analysis matrix because the repository does not contain Go source code.

The workflow uses GitHub-maintained CodeQL queries for security analysis.

## How It Runs

The workflow is located at:

`.github/workflows/codeql.yml`

CodeQL runs on:

- Pushes to `main`
- Pull requests into `main`
- A weekly scheduled scan

Pull-request scanning provides security feedback before changes are merged.

The scheduled scan allows the repository to be re-evaluated as CodeQL analysis and query coverage evolve, even when application code has not recently changed.

## Workflow Permissions

The workflow uses:

```yaml
permissions:
  contents: read
  security-events: write
