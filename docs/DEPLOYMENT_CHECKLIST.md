# Wealth360 - Deployment Checklist

## Pre-Deployment Checklist

### ☐ Environment Preparation
- [ ] Dev Hub enabled
- [ ] Salesforce CLI installed (v2.x+)
- [ ] Git repository initialized
- [ ] Node.js installed (for npm scripts)

### ☐ Code Quality
- [ ] All Apex classes have test coverage >85%
- [ ] All tests pass successfully
- [ ] No PMD/ESLint violations
- [ ] Code reviewed and approved

### ☐ Documentation
- [ ] Technical design document complete
- [ ] README.md updated
- [ ] API documentation current
- [ ] Security review documented

---

## Deployment Steps

### 1. Create Scratch Org
```bash
cd Wealth360-FSC-Assessment
sf org create scratch -f config/project-scratch-def.json -a wealth360 -d 30
```
**Expected Result**: Scratch org created successfully

### 2. Deploy Metadata
```bash
sf project deploy start --target-org wealth360
```
**Expected Result**: All components deployed without errors

### 3. Verify Deployment
```bash
sf project deploy report --target-org wealth360
```
**Check**:
- [ ] All Apex classes deployed
- [ ] LWC components deployed
- [ ] Custom fields created
- [ ] No deployment errors

### 4. Run Tests
```bash
sf apex run test --test-level RunLocalTests --code-coverage --result-format human --target-org wealth360 --wait 10
```
**Expected Results**:
- [ ] All tests pass
- [ ] Code coverage >85%
- [ ] No test failures

### 5. Configure Named Credential
**Manual Steps**:
1. Navigate to Setup → Named Credentials
2. Create new Named Credential:
   - Label: `Investment Portfolio API`
   - Name: `InvestmentPortfolioAPI`
   - URL: `https://api.mockservice.com` (or actual endpoint)
   - Identity Type: Named Principal
   - Authentication Protocol: Password Authentication (or as needed)

**Verification**:
- [ ] Named Credential created
- [ ] Test connection successful

### 6. Create Test Data
**Execute Anonymous Apex**:
```apex
// Create test Person Account
Account testAcc2 = new Account(
    FirstName = 'Lionel',
    LastName = 'Messi',
    PersonEmail = 'Lebron.James@test.com'
);
insert testAcc;

// Create Financial Account
FinServ__FinancialAccount__c fa = new FinServ__FinancialAccount__c(
    Name = 'Test Investment Portfolio',
    FinServ__PrimaryOwner__c = testAcc2.Id,
    FinServ__FinancialAccountType__c = 'Investment',
    FinServ__Status__c = 'Active',
    ExternalPortfolioId__c = 'PORT-TEST-001',
    TotalAssetValue__c = 100000.00
);
insert fa;

System.debug('Test Account ID: ' + testAcc2.Id);
System.debug('Financial Account ID: ' + fa.Id);
```

**Verification**:
- [ ] Person Account created
- [ ] Financial Account created
- [ ] Record IDs captured

### 7. Configure Page Layout
**Manual Steps**:
1. Navigate to Setup → Object Manager → Account
2. Select "Person Account Lightning Record Page"
3. Edit Page
4. Drag `wealth360Dashboard` component to page
5. Save and Activate

**Verification**:
- [ ] Component visible on Account page
- [ ] Component loads without errors

### 8. Test End-to-End Flow
**Steps**:
1. Navigate to test Account record
2. View Wealth360 Dashboard
3. Click "Sync Portfolio" button
4. Wait 5 seconds
5. Refresh page

**Expected Results**:
- [ ] Dashboard displays without errors
- [ ] Sync button triggers job
- [ ] Toast notification shows success
- [ ] Data appears after sync

---

## Post-Deployment Validation

### ☐ Functional Testing
- [ ] Dashboard loads on Account page
- [ ] Total Investment Value displays correctly
- [ ] Asset Allocation chart renders
- [ ] Recent Transactions table populates
- [ ] Sync Portfolio button works
- [ ] Loading spinners show during async operations
- [ ] Error messages display when appropriate

### ☐ Security Validation
- [ ] Users without FSC access cannot view data
- [ ] WITH SECURITY_ENFORCED prevents unauthorized access
- [ ] Named Credential used (no hardcoded credentials)
- [ ] Component respects sharing rules

### ☐ Performance Testing
- [ ] Dashboard loads in <2 seconds
- [ ] Sync completes for single account in <10 seconds
- [ ] No governor limit warnings in logs
- [ ] Large datasets (100+ holdings) render properly

---

## Rollback Plan

### If Deployment Fails
```bash
# View deployment errors
sf project deploy report --target-org wealth360

# Delete scratch org and start over
sf org delete scratch --target-org wealth360 --no-prompt

# Recreate from step 1
```

### If Tests Fail
1. Check debug logs: `sf apex get log --number 5`
2. Review test failures
3. Fix issues locally
4. Re-run tests
5. Re-deploy

---

## Production Deployment (Future)

### Additional Steps for Production
1. **Create changeset/package**:
   ```bash
   sf package version create --package Wealth360 --wait 20
   ```

2. **Deploy to UAT first**:
   ```bash
   sf project deploy start --target-org uat
   ```

3. **Run full test suite**:
   ```bash
   sf apex run test --test-level RunAllTestsInOrg
   ```

4. **Deploy to Production** (during maintenance window):
   ```bash
   sf project deploy start --target-org production --wait 30
   ```

5. **Validate deployment**:
   - Run smoke tests
   - Check logs for errors
   - Verify user access

---

## Support & Troubleshooting

### Common Issues

#### Issue: Named Credential Not Found
**Solution**:
- Verify Named Credential name matches: `InvestmentPortfolioAPI`
- Check spelling and capitalization
- Ensure credential is active

#### Issue: Dashboard Not Visible
**Solution**:
- Verify component is added to page layout
- Check user has access to LWC
- Verify FSC objects are accessible

#### Issue: Sync Button Does Nothing
**Solution**:
- Check debug logs for errors
- Verify Named Credential is configured
- Check Queueable job status: Setup → Apex Jobs

#### Issue: No Data Showing
**Solution**:
- Verify Financial Account has ExternalPortfolioId__c
- Check LastSyncDate__c is populated
- Review Holdings and Transactions exist

### Debug Commands
```bash
# View debug logs
sf apex get log --number 10

# Check job status
sf apex list log

# Query records
sf data query --query "SELECT Id, Name FROM FinServ__FinancialAccount__c LIMIT 5"
```

---

## Checklist Summary

**Before Going Live**:
- [ ] All tests pass (>85% coverage)
- [ ] Code reviewed and approved
- [ ] Security review complete
- [ ] Performance testing done
- [ ] Documentation updated
- [ ] Named Credential configured
- [ ] User training completed
- [ ] Rollback plan documented

**Deployment Day**:
- [ ] Backup current org
- [ ] Deploy during maintenance window
- [ ] Run deployment scripts
- [ ] Validate all components
- [ ] Test critical paths
- [ ] Monitor for 24 hours

**Post-Deployment**:
- [ ] User acceptance testing
- [ ] Monitor error logs
- [ ] Collect feedback
- [ ] Document lessons learned

---

**Deployment Team**:
- Developer: _________________
- QA Tester: _________________
- Release Manager: _________________
- Date: _________________

**Sign-off**:
- [ ] Development Complete
- [ ] Testing Complete
- [ ] Security Approved
- [ ] Production Ready

---

**Document Version**: 1.0  
**Last Updated**: November 22, 2025
