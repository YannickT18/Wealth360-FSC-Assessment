/**
 * @description Test class for CTRL_Wealth360Dashboard
 * @author Wealth360 Assessment
 * @date 2025-11-22
 */
@isTest
private class CTRL_Wealth360Dashboard_Test {
    
    @TestSetup
    static void setupTestData() {
        // Create test account
        Account acc = TEST_DataFactory.createAccount('TestClient', true);
        
        // Create financial accounts
        List<FinServ__FinancialAccount__c> financialAccounts = TEST_DataFactory.createFinancialAccounts(acc.Id, 2, true);
        
        // Create holdings for first financial account
        TEST_DataFactory.createAssetAllocationHoldings(financialAccounts[0].Id, true);
        
        // Create transactions
        TEST_DataFactory.createTransactions(financialAccounts[0].Id, 5, true);
    }
    
    @isTest
    static void testGetTotalInvestmentValue() {
        // Get test account
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        // Test
        Test.startTest();
        Decimal totalValue = CTRL_Wealth360Dashboard.getTotalInvestmentValue(acc.Id);
        Test.stopTest();
        
        // Verify
        Assert.areNotEqual(null, totalValue, 'Total value should not be null');
        Assert.isTrue(totalValue > 0, 'Total value should be greater than 0');
    }
    
    @isTest
    static void testGetAssetAllocation() {
        // Get test account
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        // Test
        Test.startTest();
        List<CTRL_Wealth360Dashboard.AssetAllocation> allocations = CTRL_Wealth360Dashboard.getAssetAllocation(acc.Id);
        Test.stopTest();
        
        // Verify
        Assert.areNotEqual(null, allocations, 'Allocations should not be null');
        Assert.isTrue(allocations.size() > 0, 'Should have at least one allocation');
        
        // Verify allocation data structure
        for (CTRL_Wealth360Dashboard.AssetAllocation allocation : allocations) {
            Assert.areNotEqual(null, allocation.category, 'Category should not be null');
            Assert.isTrue(allocation.value > 0, 'Value should be greater than 0');
            Assert.isTrue(allocation.percentage > 0, 'Percentage should be greater than 0');
        }
        
        // Verify percentages sum to approximately 100
        Decimal totalPercentage = 0;
        for (CTRL_Wealth360Dashboard.AssetAllocation allocation : allocations) {
            totalPercentage += allocation.percentage;
        }
        Assert.isTrue(totalPercentage >= 99 && totalPercentage <= 101, 'Total percentage should be approximately 100');
    }
    
    @isTest
    static void testGetRecentTransactions() {
        // Get test account
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        // Test
        Test.startTest();
        List<CTRL_Wealth360Dashboard.TransactionData> transactions = CTRL_Wealth360Dashboard.getRecentTransactions(acc.Id, 10);
        Test.stopTest();
        
        // Verify
        Assert.areNotEqual(null, transactions, 'Transactions should not be null');
        Assert.isTrue(transactions.size() > 0, 'Should have at least one transaction');
        
        // Verify transaction data structure
        for (CTRL_Wealth360Dashboard.TransactionData txn : transactions) {
            Assert.areNotEqual(null, txn.id, 'Transaction ID should not be null');
            Assert.areNotEqual(null, txn.type, 'Transaction type should not be null');
            Assert.areNotEqual(null, txn.amount, 'Transaction amount should not be null');
        }
    }
    
    @isTest
    static void testGetRecentTransactionsWithLimit() {
        // Get test account
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        // Test with limit of 3
        Test.startTest();
        List<CTRL_Wealth360Dashboard.TransactionData> transactions = CTRL_Wealth360Dashboard.getRecentTransactions(acc.Id, 3);
        Test.stopTest();
        
        // Verify
        Assert.isTrue(transactions.size() <= 3, 'Should have at most 3 transactions');
    }
    
    @isTest
    static void testGetPortfolioSummary() {
        // Get test account
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        // Test
        Test.startTest();
        CTRL_Wealth360Dashboard.PortfolioSummary summary = CTRL_Wealth360Dashboard.getPortfolioSummary(acc.Id);
        Test.stopTest();
        
        // Verify
        Assert.areNotEqual(null, summary, 'Summary should not be null');
        Assert.areEqual(2, summary.portfolioCount, 'Should have 2 portfolios');
        Assert.isTrue(summary.holdingsCount > 0, 'Should have holdings');
        Assert.isTrue(summary.totalValue > 0, 'Total value should be greater than 0');
    }
    
    @isTest
    static void testSyncPortfolioData() {
        // Get test account
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new Mock_InvestmentPortfolioAPI());
        
        // Test
        Test.startTest();
        String jobId = CTRL_Wealth360Dashboard.syncPortfolioData(acc.Id);
        Test.stopTest();
        
        // Verify
        Assert.areNotEqual(null, jobId, 'Job ID should not be null');
    }
    
    @isTest
    static void testGetAssetAllocationNoData() {
        // Create account with no financial accounts
        Account acc = TEST_DataFactory.createAccount('EmptyClient', true);
        
        // Test
        Test.startTest();
        List<CTRL_Wealth360Dashboard.AssetAllocation> allocations = CTRL_Wealth360Dashboard.getAssetAllocation(acc.Id);
        Test.stopTest();
        
        // Verify
        Assert.areNotEqual(null, allocations, 'Allocations should not be null');
        Assert.areEqual(0, allocations.size(), 'Should have no allocations');
    }
    
    @isTest
    static void testGetRecentTransactionsNoData() {
        // Create account with no financial accounts
        Account acc = TEST_DataFactory.createAccount('EmptyClient', true);
        
        // Test
        Test.startTest();
        List<CTRL_Wealth360Dashboard.TransactionData> transactions = CTRL_Wealth360Dashboard.getRecentTransactions(acc.Id, 10);
        Test.stopTest();
        
        // Verify
        Assert.areNotEqual(null, transactions, 'Transactions should not be null');
        Assert.areEqual(0, transactions.size(), 'Should have no transactions');
    }
    
    @isTest
    static void testErrorHandling() {
        // Test with invalid ID (should handle gracefully)
        try {
            Test.startTest();
            Decimal totalValue = CTRL_Wealth360Dashboard.getTotalInvestmentValue(null);
            Test.stopTest();
            Assert.isTrue(false, 'Should have thrown exception');
        } catch (Exception e) {
            Assert.isTrue(e instanceof AuraHandledException, 'Should throw AuraHandledException');
        }
    }
}
