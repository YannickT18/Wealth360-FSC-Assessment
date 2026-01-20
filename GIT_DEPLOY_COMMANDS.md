# Git Commands - Deploy Latest Changes

## Overview
Commands to commit and push the security model updates to GitHub.

## Changes Made
- Updated `CTRL_Wealth360Dashboard.cls` to `without sharing` (system mode)
- Updated `SRV_InvestmentPortfolio.cls` to `without sharing` (system mode)
- Updated `SRV_InvestmentPortfolioAPI.cls` to `without sharing` (system mode)
- Removed all `WITH SECURITY_ENFORCED` clauses
- Removed `Security.stripInaccessible()` calls

## Git Commands

### 1. Check Current Status
```bash
git status
```

### 2. Stage All Changes
```bash
git add .
```

Or stage specific files:
```bash
git add force-app/main/default/classes/CTRL_Wealth360Dashboard.cls
git add force-app/main/default/classes/SRV_InvestmentPortfolio.cls
git add force-app/main/default/classes/SRV_InvestmentPortfolioAPI.cls
```

### 3. Commit Changes
```bash
git commit -m "Simplify security model - use system mode without sharing"
```

Or with detailed message:
```bash
git commit -m "Refactor: Simplify security model to use system mode

- Changed all controller/service classes to 'without sharing'
- Removed WITH SECURITY_ENFORCED from all queries
- Removed Security.stripInaccessible() calls
- Platform security on Account page controls access
- Services run in system mode for full data access"
```

### 4. Push to GitHub
```bash
git push origin main
```

If this is your first push or you need to set upstream:
```bash
git push -u origin main
```

### 5. Verify Push
```bash
git log --oneline -5
```

## Additional Useful Commands

### View Changes Before Committing
```bash
git diff
```

### View Staged Changes
```bash
git diff --staged
```

### Undo Staged Changes (if needed)
```bash
git reset HEAD <file>
```

### View Commit History
```bash
git log --oneline --graph --all
```

### Pull Latest Changes (before pushing)
```bash
git pull origin main
```

## Complete Workflow (Copy & Paste)

```bash
# Check status
git status

# Stage all changes
git add .

# Commit with message
git commit -m "Simplify security model - use system mode without sharing"

# Push to GitHub
git push origin main

# Verify
git log --oneline -5
```

## Notes

- Platform security controls access at the page level
- LWC placed on Account page = only authorized users can access
- System mode provides full data access for reporting/dashboard features
- No need for excessive security checks in controller layer
