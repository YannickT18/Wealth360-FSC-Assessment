/**
 * @description Test class for SRV_PortfolioUpdate
 * @author Yannick Kayombo
 * @date 22-11-2025
 */
@isTest
private class SRV_PortfolioUpdate_Test {
    
    @TestSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = TEST_DataFactory.createAccount('Investment Account', true);
        
        // Custom metadata test records are handled by the system
        // We'll mock the metadata queries in individual tests
    }
    
    /**
     * @description Test successful comprehensive portfolio data sync
     */
    @isTest
    static void testSyncComprehensivePortfolioData_Success() {
        // Setup
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        SRV_InvestmentPortfolioAPI.ComprehensivePortfolioData testData = createMockComprehensiveData();
        
        // Execute
        Test.startTest();
        SRV_PortfolioUpdate.syncComprehensivePortfolioData(testAccount.Id, testData);
        Test.stopTest();
        
        // Verify Financial Accounts were created
        List<FinServ__FinancialAccount__c> financialAccounts = [
            SELECT Id, ExternalPortfolioId__c, FinServ__PrimaryOwner__c, LastSyncDate__c
            FROM FinServ__FinancialAccount__c
            WHERE FinServ__PrimaryOwner__c = :testAccount.Id
        ];
        
        Assert.areEqual(1, financialAccounts.size(), 'Should create one financial account');
        Assert.areEqual('PORTFOLIO123', financialAccounts[0].ExternalPortfolioId__c);
        Assert.areEqual(testAccount.Id, financialAccounts[0].FinServ__PrimaryOwner__c);
        Assert.isNotNull(financialAccounts[0].LastSyncDate__c);
    }
    
    /**
     * @description Test portfolio sync with holdings and transactions
     */
    @isTest
    static void testSyncComprehensivePortfolioData_WithHoldingsAndTransactions() {
        // Setup
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        SRV_InvestmentPortfolioAPI.ComprehensivePortfolioData testData = createMockComprehensiveData();
        
        // Execute
        Test.startTest();
        SRV_PortfolioUpdate.syncComprehensivePortfolioData(testAccount.Id, testData);
        Test.stopTest();
        
        // Verify Financial Holdings were created
        List<FinServ__FinancialHolding__c> holdings = [
            SELECT Id, ExternalHoldingId__c, FinServ__FinancialAccount__c
            FROM FinServ__FinancialHolding__c
        ];
        
        Assert.areEqual(1, holdings.size(), 'Should create one financial holding');
        Assert.areEqual('HOLDING123', holdings[0].ExternalHoldingId__c);
        
        // Verify Financial Account Transactions were created
        List<FinServ__FinancialAccountTransaction__c> transactions = [
            SELECT Id, ExternalTransactionId__c, FinServ__FinancialAccount__c
            FROM FinServ__FinancialAccountTransaction__c
        ];
        
        Assert.areEqual(1, transactions.size(), 'Should create one transaction');
        Assert.areEqual('TXN123', transactions[0].ExternalTransactionId__c);
    }
    
    /**
     * @description Test handling of empty comprehensive data
     */
    @isTest
    static void testSyncComprehensivePortfolioData_EmptyData() {
        // Setup
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        SRV_InvestmentPortfolioAPI.ComprehensivePortfolioData emptyData = 
            new SRV_InvestmentPortfolioAPI.ComprehensivePortfolioData();
        
        // Execute
        Test.startTest();
        SRV_PortfolioUpdate.syncComprehensivePortfolioData(testAccount.Id, emptyData);
        Test.stopTest();
        
        // Verify no records were created
        Assert.areEqual(0, [SELECT COUNT() FROM FinServ__FinancialAccount__c WHERE FinServ__PrimaryOwner__c = :testAccount.Id]);
        Assert.areEqual(0, [SELECT COUNT() FROM FinServ__FinancialHolding__c]);
        Assert.areEqual(0, [SELECT COUNT() FROM FinServ__FinancialAccountTransaction__c]);
    }
    
    /**
     * @description Test error handling for invalid data
     */
    @isTest
    static void testSyncComprehensivePortfolioData_InvalidData() {
        // Setup
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        SRV_InvestmentPortfolioAPI.ComprehensivePortfolioData invalidData = createInvalidComprehensiveData();
        
        // Execute & Verify
        Test.startTest();
        try {
            SRV_PortfolioUpdate.syncComprehensivePortfolioData(testAccount.Id, invalidData);
            Assert.fail('Should have thrown an exception for invalid data');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Failed to sync'), 'Should throw meaningful error message');
        }
        Test.stopTest();
    }
    
    /**
     * @description Test type conversion functionality
     */
    @isTest
    static void testTypeConversion() {
        // This tests the private convertValue method indirectly through field mappings
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        // Create test data with various data types
        Map<String, Object> portfolioData = new Map<String, Object>{
            'id' => 'TEST123',
            'name' => 'Test Portfolio',
            'total_value' => '50000.50',  // String that should convert to Decimal
            'created_date' => '2024-01-01'  // String that should convert to Date
        };
        
        SRV_InvestmentPortfolioAPI.ComprehensivePortfolioData testData = 
            new SRV_InvestmentPortfolioAPI.ComprehensivePortfolioData();
        testData.portfolios.add(portfolioData);
        
        Test.startTest();
        SRV_PortfolioUpdate.syncComprehensivePortfolioData(testAccount.Id, testData);
        Test.stopTest();
        
        // Verify the record was created (type conversion worked)
        List<FinServ__FinancialAccount__c> accounts = [
            SELECT Id, ExternalPortfolioId__c
            FROM FinServ__FinancialAccount__c
            WHERE FinServ__PrimaryOwner__c = :testAccount.Id
        ];
        
        Assert.areEqual(1, accounts.size(), 'Should create account despite type conversions');
    }
    
    /**
     * @description Test bulk operations
     */
    @isTest
    static void testBulkOperations() {
        // Setup
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        SRV_InvestmentPortfolioAPI.ComprehensivePortfolioData bulkData = createBulkComprehensiveData();
        
        // Execute
        Test.startTest();
        SRV_PortfolioUpdate.syncComprehensivePortfolioData(testAccount.Id, bulkData);
        Test.stopTest();
        
        // Verify multiple records were processed
        Assert.areEqual(3, [SELECT COUNT() FROM FinServ__FinancialAccount__c WHERE FinServ__PrimaryOwner__c = :testAccount.Id]);
        Assert.areEqual(3, [SELECT COUNT() FROM FinServ__FinancialHolding__c]);
        Assert.areEqual(3, [SELECT COUNT() FROM FinServ__FinancialAccountTransaction__c]);
    }
    
    // Helper Methods
    
    /**
     * @description Create mock comprehensive portfolio data for testing
     */
    private static SRV_InvestmentPortfolioAPI.ComprehensivePortfolioData createMockComprehensiveData() {
        SRV_InvestmentPortfolioAPI.ComprehensivePortfolioData data = 
            new SRV_InvestmentPortfolioAPI.ComprehensivePortfolioData();
        
        // Portfolio data
        Map<String, Object> portfolioData = new Map<String, Object>{
            'id' => 'PORTFOLIO123',
            'name' => 'Test Investment Portfolio',
            'type' => 'Investment',
            'total_value' => 25000.00
        };
        data.portfolios.add(portfolioData);
        
        // Holdings data
        List<Map<String, Object>> holdings = new List<Map<String, Object>>{
            new Map<String, Object>{
                'id' => 'HOLDING123',
                'portfolio_id' => 'PORTFOLIO123',
                'symbol' => 'AAPL',
                'quantity' => 100,
                'market_value' => 15000.00
            }
        };
        data.holdingsByPortfolio.put('PORTFOLIO123', holdings);
        
        // Transaction data
        List<Map<String, Object>> transactions = new List<Map<String, Object>>{
            new Map<String, Object>{
                'id' => 'TXN123',
                'portfolio_id' => 'PORTFOLIO123',
                'type' => 'Buy',
                'amount' => 5000.00,
                'transaction_date' => Date.today().addDays(-1)
            }
        };
        data.transactionsByPortfolio.put('PORTFOLIO123', transactions);
        
        return data;
    }
    
    /**
     * @description Create invalid comprehensive data for error testing
     */
    private static SRV_InvestmentPortfolioAPI.ComprehensivePortfolioData createInvalidComprehensiveData() {
        SRV_InvestmentPortfolioAPI.ComprehensivePortfolioData data = 
            new SRV_InvestmentPortfolioAPI.ComprehensivePortfolioData();
        
        // Portfolio data missing required fields
        Map<String, Object> portfolioData = new Map<String, Object>{
            'invalid_field' => 'test'
        };
        data.portfolios.add(portfolioData);
        
        return data;
    }
    
    /**
     * @description Create bulk test data for volume testing
     */
    private static SRV_InvestmentPortfolioAPI.ComprehensivePortfolioData createBulkComprehensiveData() {
        SRV_InvestmentPortfolioAPI.ComprehensivePortfolioData data = 
            new SRV_InvestmentPortfolioAPI.ComprehensivePortfolioData();
        
        // Create 3 portfolios with holdings and transactions
        for (Integer i = 1; i <= 3; i++) {
            String portfolioId = 'PORTFOLIO' + i;
            
            // Portfolio
            Map<String, Object> portfolioData = new Map<String, Object>{
                'id' => portfolioId,
                'name' => 'Test Portfolio ' + i,
                'type' => 'Investment',
                'total_value' => 10000.00 * i
            };
            data.portfolios.add(portfolioData);
            
            // Holdings
            List<Map<String, Object>> holdings = new List<Map<String, Object>>{
                new Map<String, Object>{
                    'id' => 'HOLDING' + i,
                    'portfolio_id' => portfolioId,
                    'symbol' => 'TEST' + i,
                    'quantity' => 50 * i,
                    'market_value' => 5000.00 * i
                }
            };
            data.holdingsByPortfolio.put(portfolioId, holdings);
            
            // Transactions
            List<Map<String, Object>> transactions = new List<Map<String, Object>>{
                new Map<String, Object>{
                    'id' => 'TXN' + i,
                    'portfolio_id' => portfolioId,
                    'type' => 'Buy',
                    'amount' => 2500.00 * i,
                    'transaction_date' => Date.today().addDays(-i)
                }
            };
            data.transactionsByPortfolio.put(portfolioId, transactions);
        }
        
        return data;
    }
}