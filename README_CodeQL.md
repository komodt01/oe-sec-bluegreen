CodeQL: Static Application Security Testing (SAST)
Why it’s here (business → outcomes)

This repository uses GitHub CodeQL to automatically detect security and quality issues in code. It supports two Well-Architected pillars:

Security – early detection of vulnerable patterns (injection, deserialization, insecure randomness, etc.).

Operational Excellence – repeatable, automated reviews on every PR and a scheduled full scan to keep debt visible.

Strategy first; tools second. CodeQL is used here because GitHub recommends it for code scanning in GitHub-hosted projects. In any client/enterprise setting the tool choice would follow business goals, platform, and policy.

What it scans
Languages enabled in this repo: Python and JavaScript.
(Go was removed from the matrix because there’s no Go source in this repo.)

Query packs: the default security + quality packs maintained by GitHub.

How it runs
The workflow lives at: .github/workflows/codeql.yml.

It triggers on:
Push to main
Pull requests into main (shifts left: comments on the PR)
Weekly schedule (cron) for drift and new query coverage

Minimal permissions:
permissions:
  contents: read
  security-events: write

Build step:
- uses: github/codeql-action/autobuild@v3

Where results appear
Security → Code scanning alerts (repository tab)
Pull request checks (inline annotations on changed lines)
SARIF is uploaded to GitHub’s security events and retained with the run

Triage workflow (lightweight)
Open Security → Code scanning alerts.
For each alert:
Confirm: real issue vs. FP (false positive).
Decide:
Fix now (link shows the exact location and query docs).
Dismiss with a reason (won’t fix / used in tests / acceptable risk).
Track: convert to issue if fix spans multiple PRs.
Tie fixes to a PR and reference the alert. The check will re-run and close the alert automatically when the pattern disappears.
Customizing

Languages: edit the matrix in the workflow:
matrix:
  language: ['python', 'javascript']

  Queries: add packs or custom queries:
  - uses: github/codeql-action/init@v3
  with:
    languages: ${{ matrix.language }}
    queries: security-extended,security-and-quality

Monorepo: scope analysis with paths / paths-ignore in the workflow trigger or with CodeQL packs config.

Troubleshooting (common)
“No source code seen during build (Go/Python/JS)”
The matrix includes a language without files. Remove it or add source.
(We already removed go in this repo.)

Autobuild fails
Replace autobuild with explicit build commands for your stack.

No alerts but you expect some
Ensure code is actually analyzed (check the job summary), and that queries are not limited to a minimal set. Try security-extended.

Complementary controls
Dependabot: automated PRs for vulnerable/outdated dependencies (enabled in this repo).
Secret scanning: enable repository-level secret scanning and push protection if available.
Branch protection: require CodeQL and tests to pass before merge.

Governance notes
Keep CodeQL action versions pinned to the latest major (@v3).
Scheduled runs help capture new query detections without code changes.
Treat dismissals as risk decisions; always record a reason

Change log
Initial setup: CodeQL enabled for Python and JavaScript, weekly schedule.
Removed Go analyzer (no Go source present).
