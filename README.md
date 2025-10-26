# 🛡️ Blue/Green CodeQL Security Automation

This repository demonstrates **secure DevOps pipeline practices** using GitHub Actions, CodeQL static analysis, and blue/green deployment strategies. It integrates code scanning, continuous integration (CI), and branch protection to enforce strong security and compliance in cloud-oriented development environments.

---

## 📘 Purpose

The goal of this project is to:
- Showcase automated **CodeQL vulnerability scanning** for JavaScript projects.
- Enforce **branch protection rules** that require successful security checks.
- Illustrate a **blue/green deployment approach** where validated code changes are promoted between branches or environments without downtime.
- Demonstrate **CI workflow resiliency**—ensuring that documentation-only commits (e.g., README or `.md` updates) do **not trigger unnecessary CodeQL failures**.

---

## ⚙️ How It Works

1. **CodeQL Analysis Workflow**
   - Automatically triggered on:
     - Pushes to the `main` branch
     - Pull requests to `main`
   - Ignores Markdown and documentation-only commits.
   - Dynamically detects if JavaScript/TypeScript files exist; skips analysis gracefully if not.
   - Reports findings to GitHub Security → Code Scanning Alerts.

2. **Branch Protection**
   - Enforces `ci` and `CodeQL` checks as required before merging.
   - Prevents force pushes or direct merges to `main`.
   - Enables reliable verification in multi-developer or blue/green environments.

3. **CI Integration**
   - Uses GitHub’s `lint-and-synth` and CodeQL checks.
   - Ensures all PRs meet code quality and security standards before promotion.

---

## 🧩 Key Files

| File | Description |
|------|--------------|
| `.github/workflows/codeql.yml` | CodeQL workflow that performs static analysis for JavaScript. |
| `.github/workflows/ci.yml` | Linting and syntax validation pipeline (if applicable). |
| `README.md` | This file, describing repository structure and purpose. |

---

## 🧪 Testing the Workflow

Run a test scan locally or via a new PR:
```bash
# Create a new branch
git checkout -b test-codeql

# Make a small change
echo "// test" >> app.js

# Commit and push
git add .
git commit -m "test: trigger CodeQL analysis"
git push origin test-codeql
