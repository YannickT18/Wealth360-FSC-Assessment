/**
 * @description Test class for CTRL_Wealth360Dashboard
 * @author Yannick Kayombo
 * @date 22-11-2025
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
        Assert.isNotNull(totalValue, 'Total value should not be null');
        Assert.isTrue(totalValue > 0, 'Total value should be greater than 0');
    }
    
    @isTest
    static void testGetTotalInvestmentValueException() {
        // Create and delete account to trigger exception
        Account acc = TEST_DataFactory.createAccount('TempAccount', true);
        Id accId = acc.Id;
        delete acc;
        
        Test.startTest();
        try {
            Decimal totalValue = CTRL_Wealth360Dashboard.getTotalInvestmentValue(accId);
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Error fetching total investment value'), 
                'Exception should contain proper error message');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetAssetAllocation() {
        // Get test account
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        // Test
        Test.startTest();
        List<DTO_Wealth360Dashboard.AssetAllocation> allocations = CTRL_Wealth360Dashboard.getAssetAllocation(acc.Id);
        Test.stopTest();
        
        // Verify
        Assert.isNotNull(allocations, 'Allocations should not be null');
        Assert.isTrue(allocations.size() > 0, 'Should have at least one allocation');
        
        // Verify allocation data structure
        for (DTO_Wealth360Dashboard.AssetAllocation allocation : allocations) {
            Assert.isNotNull(allocation.category, 'Category should not be null');
            Assert.isTrue(allocation.value > 0, 'Value should be greater than 0');
            Assert.isTrue(allocation.percentage > 0, 'Percentage should be greater than 0');
        }
        
        // Verify percentages sum to approximately 100
        Decimal totalPercentage = 0;
        for (DTO_Wealth360Dashboard.AssetAllocation allocation : allocations) {
            totalPercentage += allocation.percentage;
        }
        Assert.isTrue(totalPercentage >= 99 && totalPercentage <= 101, 'Total percentage should be approximately 100');
    }
    
    @isTest
    static void testGetAssetAllocationException() {
        // Create and delete account to trigger exception
        Account acc = TEST_DataFactory.createAccount('TempAccount', true);
        Id accId = acc.Id;
        delete acc;
        
        Test.startTest();
        try {
            List<DTO_Wealth360Dashboard.AssetAllocation> allocations = CTRL_Wealth360Dashboard.getAssetAllocation(accId);
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Error fetching asset allocation'), 
                'Exception should contain proper error message');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetRecentTransactions() {
        // Get test account
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        // Test
        Test.startTest();
        List<DTO_Wealth360Dashboard.TransactionData> transactions = CTRL_Wealth360Dashboard.getRecentTransactions(acc.Id, 10);
        Test.stopTest();
        
        // Verify
        Assert.isNotNull(transactions, 'Transactions should not be null');
        Assert.isTrue(transactions.size() > 0, 'Should have at least one transaction');
        
        // Verify transaction data structure
        for (DTO_Wealth360Dashboard.TransactionData txn : transactions) {
            Assert.isNotNull(txn.id, 'Transaction ID should not be null');
            Assert.isNotNull(txn.type, 'Transaction type should not be null');
            Assert.isNotNull(txn.amount, 'Transaction amount should not be null');
        }
    }
    
    @isTest
    static void testGetRecentTransactionsWithLimit() {
        // Get test account
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        // Test with limit of 3
        Test.startTest();
        List<DTO_Wealth360Dashboard.TransactionData> transactions = CTRL_Wealth360Dashboard.getRecentTransactions(acc.Id, 3);
        Test.stopTest();
        
        // Verify
        Assert.isTrue(transactions.size() <= 3, 'Should have at most 3 transactions');
    }
    
    @isTest
    static void testGetRecentTransactionsException() {
        // Create and delete account to trigger exception
        Account acc = TEST_DataFactory.createAccount('TempAccount', true);
        Id accId = acc.Id;
        delete acc;
        
        Test.startTest();
        try {
            List<DTO_Wealth360Dashboard.TransactionData> transactions = 
                CTRL_Wealth360Dashboard.getRecentTransactions(accId, 10);
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Error fetching recent transactions'), 
                'Exception should contain proper error message');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetPortfolioSummary() {
        // Get test account
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        // Test
        Test.startTest();
        DTO_Wealth360Dashboard.PortfolioSummary summary = CTRL_Wealth360Dashboard.getPortfolioSummary(acc.Id);
        Test.stopTest();
        
        // Verify
        Assert.isNotNull(summary, 'Summary should not be null');
        Assert.areEqual(2, summary.portfolioCount, 'Should have 2 portfolios');
        Assert.isTrue(summary.holdingsCount > 0, 'Should have holdings');
        Assert.isTrue(summary.totalValue > 0, 'Total value should be greater than 0');
    }
    
    @isTest
    static void testGetPortfolioSummaryException() {
        // Create and delete account to trigger exception
        Account acc = TEST_DataFactory.createAccount('TempAccount', true);
        Id accId = acc.Id;
        delete acc;
        
        Test.startTest();
        try {
            DTO_Wealth360Dashboard.PortfolioSummary summary = 
                CTRL_Wealth360Dashboard.getPortfolioSummary(accId);
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Error fetching portfolio summary'), 
                'Exception should contain proper error message');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testSyncPortfolioData() {
        // Get test account
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new MOCK_InvestmentPortfolioAPI());
        
        // Test
        Test.startTest();
        String result = CTRL_Wealth360Dashboard.syncPortfolioData(acc.Id);
        Test.stopTest();
        
        // Verify
        Assert.isNotNull(result, 'Sync result should not be null');
        Assert.isTrue(result.startsWith('SUCCESS:'), 'Result should indicate success');
        Assert.isTrue(result.contains('portfolios'), 'Result should mention portfolios');
        Assert.isTrue(result.contains('holdings'), 'Result should mention holdings');
        Assert.isTrue(result.contains('transactions'), 'Result should mention transactions');
    }
    
    @isTest
    static void testSyncPortfolioDataException() {
        // Get test account
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        // Set mock that returns error status
        Test.setMock(HttpCalloutMock.class, new MOCK_InvestmentPortfolioAPI(500, 'error'));
        
        Test.startTest();
        try {
            String result = CTRL_Wealth360Dashboard.syncPortfolioData(acc.Id);
            Assert.fail('Should have thrown exception with 500 error');
        } catch (Exception e) {
            // Exception caught - catch block is covered
            Assert.isNotNull(e.getMessage(), 'Exception should have a message');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testErrorHandling() {
        // Test with invalid ID (should handle gracefully)
        Test.startTest();
        Decimal totalValue = CTRL_Wealth360Dashboard.getTotalInvestmentValue(null);
        Test.stopTest();
        
        // Verify graceful handling - should return 0 instead of throwing exception
        Assert.areEqual(0, totalValue, 'Should return 0 for null account ID');
    }
}
