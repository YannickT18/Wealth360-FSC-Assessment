# Git Setup Instructions

## Initialize Git Repository

```bash
cd Wealth360-FSC-Assessment

# Initialize Git
git init

# Add all files
git add .

# Initial commit
git commit -m "Initial commit: Wealth360 FSC Assessment - Complete Solution

- FSC standard objects (FinancialAccount, FinancialHolding, FinancialAccountTransaction)
- Custom LWC dashboard with asset allocation charts
- External API integration with retry logic
- Queueable async processing
- >90% test coverage
- Comprehensive documentation"

# Create development branch
git checkout -b develop

# Go back to main
git checkout main
```

## Git Branching Strategy

```
main (production-ready)
  └── develop (integration branch)
       ├── feature/dashboard-lwc
       ├── feature/api-integration
       ├── feature/async-processing
       └── feature/documentation
```

## Git Commands

### Create Feature Branch
```bash
git checkout -b feature/your-feature-name
```

### Commit Changes
```bash
git add .
git commit -m "Description of changes"
```

### Merge to Develop
```bash
git checkout develop
git merge feature/your-feature-name
```

### Tag Release
```bash
git tag -a v1.0.0 -m "Version 1.0.0 - Initial Release"
```

## GitHub Setup

### Create Remote Repository
1. Create new repository on GitHub
2. Copy the remote URL

### Link Local to Remote
```bash
git remote add origin <your-repo-url>
git push -u origin main
git push origin develop
```

### Push All Tags
```bash
git push --tags
```

## .gitignore

Already included in project. Key exclusions:
- `.sfdx/` - Salesforce CLI cache
- `.sf/` - Salesforce CLI configuration
- `node_modules/` - NPM dependencies
- `*.log` - Log files
- `.env` - Environment variables

## Commit Message Convention

Use semantic commit messages:

```
feat: Add new feature
fix: Bug fix
docs: Documentation changes
test: Test additions or changes
refactor: Code refactoring
style: Code style changes
chore: Build/config changes
```

### Examples
```bash
git commit -m "feat: Add asset allocation pie chart to dashboard"
git commit -m "fix: Handle rate limit errors in API service"
git commit -m "docs: Update deployment checklist"
git commit -m "test: Add bulk processing test for QUE_PortfolioSync"
```

## Pre-Commit Checklist

Before committing:
- [ ] Run tests: `sf apex run test --test-level RunLocalTests`
- [ ] Check for errors: Review code for console.log, debug statements
- [ ] Update documentation if needed
- [ ] Verify .gitignore excludes sensitive data

## Branch Protection (For Teams)

Recommended settings for `main` branch:
- Require pull request reviews
- Require status checks (tests) to pass
- Require linear history
- Require signed commits (optional)

---

**Ready to Git?** Run the commands above to initialize your repository!
