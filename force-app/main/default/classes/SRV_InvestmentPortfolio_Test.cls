/**
 * @description Test class for SRV_InvestmentPortfolioAPI
 * @author Wealth360 Assessment
 * @date 2025-11-22
 * 
 * Best Practices:
 * - Uses Test.setMock() for HTTP callouts
 * - Tests positive and negative scenarios
 * - Follows AAA pattern (Arrange, Act, Assert)
 * - Uses meaningful assertions
 * - Tests error handling (429, 500 errors)
 */
@isTest
private class SRV_InvestmentPortfolio_Test {
    
    @isTest
    static void testGetPortfoliosSuccess() {
        // Setup
        Account acc = TEST_DataFactory.createAccount('TestClient', true);
        
        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new Mock_InvestmentPortfolioAPI());
        
        // Test
        Test.startTest();
        SRV_InvestmentPortfolioAPI.APIResponse response = 
            SRV_InvestmentPortfolioAPI.getPortfolios(acc.Id);
        Test.stopTest();
        
        // Verify
        Assert.isTrue(response.success, 'Response should be successful');
        Assert.areEqual(200, response.statusCode, 'Status code should be 200');
        Assert.areNotEqual(null, response.data, 'Response data should not be null');
        
        // Verify data structure
        Map<String, Object> responseData = (Map<String, Object>)response.data;
        Assert.isTrue(responseData.containsKey('portfolios'), 'Response should contain portfolios');
    }
    
    @isTest
    static void testGetPortfolioByIdSuccess() {
        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new Mock_InvestmentPortfolioAPI());
        
        // Test
        Test.startTest();
        SRV_InvestmentPortfolioAPI.APIResponse response = 
            SRV_InvestmentPortfolioAPI.getPortfolioById('PORT-001');
        Test.stopTest();
        
        // Verify
        Assert.isTrue(response.success, 'Response should be successful');
        Assert.areEqual(200, response.statusCode, 'Status code should be 200');
    }
    
    @isTest
    static void testGetHoldingsSuccess() {
        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new Mock_InvestmentPortfolioAPI());
        
        // Test
        Test.startTest();
        SRV_InvestmentPortfolioAPI.APIResponse response = 
            SRV_InvestmentPortfolioAPI.getHoldings('PORT-001');
        Test.stopTest();
        
        // Verify
        Assert.isTrue(response.success, 'Response should be successful');
        Assert.areEqual(200, response.statusCode, 'Status code should be 200');
        
        Map<String, Object> responseData = (Map<String, Object>)response.data;
        Assert.isTrue(responseData.containsKey('holdings'), 'Response should contain holdings');
    }
    
    @isTest
    static void testGetTransactionsSuccess() {
        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new Mock_InvestmentPortfolioAPI());
        
        Date startDate = System.today().addDays(-30);
        Date endDate = System.today();
        
        // Test
        Test.startTest();
        SRV_InvestmentPortfolioAPI.APIResponse response = 
            SRV_InvestmentPortfolioAPI.getTransactions('PORT-001', startDate, endDate);
        Test.stopTest();
        
        // Verify
        Assert.isTrue(response.success, 'Response should be successful');
        Assert.areEqual(200, response.statusCode, 'Status code should be 200');
        
        Map<String, Object> responseData = (Map<String, Object>)response.data;
        Assert.isTrue(responseData.containsKey('transactions'), 
                     'Response should contain transactions');
    }
    
    @isTest
    static void testRateLimitError() {
        // Set mock callout with rate limit error
        Test.setMock(HttpCalloutMock.class, new Mock_InvestmentPortfolioAPI(429, 'error'));
        
        Account acc = TEST_DataFactory.createAccount('TestClient', true);
        
        // Test
        Test.startTest();
        SRV_InvestmentPortfolioAPI.APIResponse response = 
            SRV_InvestmentPortfolioAPI.getPortfolios(acc.Id);
        Test.stopTest();
        
        // Verify
        Assert.isTrue(!response.success, 'Response should fail');
        Assert.areEqual(429, response.statusCode, 'Status code should be 429');
        Assert.isTrue(response.errorMessage.contains('Rate limit'), 
                     'Error message should mention rate limit');
    }
    
    @isTest
    static void testServerError() {
        // Set mock callout with server error
        Test.setMock(HttpCalloutMock.class, new Mock_InvestmentPortfolioAPI(500, 'error'));
        
        Account acc = TEST_DataFactory.createAccount('TestClient', true);
        
        // Test
        Test.startTest();
        SRV_InvestmentPortfolioAPI.APIResponse response = 
            SRV_InvestmentPortfolioAPI.getPortfolios(acc.Id);
        Test.stopTest();
        
        // Verify
        Assert.isTrue(!response.success, 'Response should fail');
        Assert.areEqual(500, response.statusCode, 'Status code should be 500');
    }
    
    @isTest
    static void testParsePortfolios() {
        // Setup mock response data
        Map<String, Object> responseData = new Map<String, Object>{
            'success' => true,
            'portfolios' => new List<Object>{
                new Map<String, Object>{
                    'portfolioId' => 'PORT-001',
                    'name' => 'Test Portfolio',
                    'totalValue' => 100000.00
                }
            }
        };
        
        // Test
        Test.startTest();
        List<Map<String, Object>> portfolios = 
            SRV_InvestmentPortfolioAPI.parsePortfolios(responseData);
        Test.stopTest();
        
        // Verify
        Assert.areEqual(1, portfolios.size(), 'Should have 1 portfolio');
        Assert.areEqual('PORT-001', portfolios[0].get('portfolioId'), 
                          'Portfolio ID should match');
    }
    
    @isTest
    static void testParseHoldings() {
        // Setup mock response data
        Map<String, Object> responseData = new Map<String, Object>{
            'success' => true,
            'holdings' => new List<Object>{
                new Map<String, Object>{
                    'holdingId' => 'HOLD-001',
                    'assetCategory' => 'Stocks',
                    'currentValue' => 50000.00
                }
            }
        };
        
        // Test
        Test.startTest();
        List<Map<String, Object>> holdings = 
            SRV_InvestmentPortfolioAPI.parseHoldings(responseData);
        Test.stopTest();
        
        // Verify
        Assert.areEqual(1, holdings.size(), 'Should have 1 holding');
        Assert.areEqual('HOLD-001', holdings[0].get('holdingId'), 
                          'Holding ID should match');
    }
    
    @isTest
    static void testParseTransactions() {
        // Setup mock response data
        Map<String, Object> responseData = new Map<String, Object>{
            'success' => true,
            'transactions' => new List<Object>{
                new Map<String, Object>{
                    'transactionId' => 'TXN-001',
                    'type' => 'Buy',
                    'amount' => 5000.00
                }
            }
        };
        
        // Test
        Test.startTest();
        List<Map<String, Object>> transactions = 
            SRV_InvestmentPortfolioAPI.parseTransactions(responseData);
        Test.stopTest();
        
        // Verify
        Assert.areEqual(1, transactions.size(), 'Should have 1 transaction');
        Assert.areEqual('TXN-001', transactions[0].get('transactionId'), 
                          'Transaction ID should match');
    }
}

