/**
 * @description Test class for SRV_InvestmentPortfolioAPI
 * @author Yannick Kayombo
 * @date 22-11-2025
 */

@isTest
private class SRV_InvestmentPortfolio_Test {
    
    @isTest
    static void testGetComprehensivePortfolioDataSuccess() {
        // Setup
        Account acc = TEST_DataFactory.createAccount('TestClient', true);
        
        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new Mock_InvestmentPortfolioAPI());
        
        // Test
        Test.startTest();
        SRV_InvestmentPortfolioAPI.APIResponse response = 
            SRV_InvestmentPortfolioAPI.getComprehensivePortfolioData(acc.Id, false, false, 0);
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
        // Setup
        Account acc = TEST_DataFactory.createAccount('TestClient', true);
        
        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new Mock_InvestmentPortfolioAPI());
        
        // Test
        Test.startTest();
        SRV_InvestmentPortfolioAPI.APIResponse response = 
            SRV_InvestmentPortfolioAPI.getComprehensivePortfolioData(acc.Id, false, false, 0);
        Test.stopTest();
        
        // Verify
        Assert.isTrue(response.success, 'Response should be successful');
        Assert.areEqual(200, response.statusCode, 'Status code should be 200');
    }
    
    @isTest
    static void testGetHoldingsSuccess() {
        // Setup
        Account acc = TEST_DataFactory.createAccount('TestClient', true);
        
        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new Mock_InvestmentPortfolioAPI());
        
        // Test
        Test.startTest();
        SRV_InvestmentPortfolioAPI.APIResponse response = 
            SRV_InvestmentPortfolioAPI.getComprehensivePortfolioData(acc.Id, true, false, 0);
        Test.stopTest();
        
        // Verify
        Assert.isTrue(response.success, 'Response should be successful');
        Assert.areEqual(200, response.statusCode, 'Status code should be 200');
        
        Map<String, Object> responseData = (Map<String, Object>)response.data;
        Assert.isTrue(responseData.containsKey('holdings'), 'Response should contain holdings');
    }
    
    @isTest
    static void testGetTransactionsSuccess() {
        // Setup
        Account acc = TEST_DataFactory.createAccount('TestClient', true);
        
        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new Mock_InvestmentPortfolioAPI());
        
        Date startDate = System.today().addDays(-30);
        Date endDate = System.today();
        
        // Test
        Test.startTest();
        SRV_InvestmentPortfolioAPI.APIResponse response = 
            SRV_InvestmentPortfolioAPI.getComprehensivePortfolioData(acc.Id, false, true, 30);
        Test.stopTest();
        
        // Verify
        Assert.isTrue(response.success, 'Response should be successful');
        Assert.areEqual(200, response.statusCode, 'Status code should be 200');
        
        Map<String, Object> responseData = (Map<String, Object>)response.data;
        Assert.isTrue(responseData.containsKey('transactions'), 'Response should contain transactions');
    }
    
    @isTest
    static void testRateLimitError() {
        // Set mock callout with rate limit error
        Test.setMock(HttpCalloutMock.class, new TEST_DataFactory.Mock_InvestmentPortfolioAPI(429, 'error'));
        
        Account acc = TEST_DataFactory.createAccount('TestClient', true);
        
        // Test
        Test.startTest();
        SRV_InvestmentPortfolioAPI.APIResponse response = 
            SRV_InvestmentPortfolioAPI.getComprehensivePortfolioData(acc.Id, false, false, 0);
        Test.stopTest();
        
        // Verify
        Assert.isTrue(!response.success, 'Response should fail');
        Assert.areEqual(429, response.statusCode, 'Status code should be 429');
        Assert.isTrue(response.errorMessage.contains('Rate limit'),  'Error message should mention rate limit');
    }
    
    @isTest
    static void testServerError() {
        // Set mock callout with server error
        Test.setMock(HttpCalloutMock.class, new Mock_InvestmentPortfolioAPI(500, 'error'));
        
        Account acc = TEST_DataFactory.createAccount('TestClient', true);
        
        // Test
        Test.startTest();
        SRV_InvestmentPortfolioAPI.APIResponse response = 
            SRV_InvestmentPortfolioAPI.getComprehensivePortfolioData(acc.Id, false, false, 0);
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
        SRV_InvestmentPortfolioAPI.ComprehensivePortfolioData parsedData = 
            SRV_InvestmentPortfolioAPI.parseComprehensiveData(responseData);
        Test.stopTest();
        
        // Verify
        Assert.areEqual(1, parsedData.portfolios.size(), 'Should have 1 portfolio');
        Assert.areEqual('PORT-001', parsedData.portfolios[0].get('portfolioId'), 'Portfolio ID should match');
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
        SRV_InvestmentPortfolioAPI.ComprehensivePortfolioData parsedData = 
            SRV_InvestmentPortfolioAPI.parseComprehensiveData(responseData);
        Test.stopTest();
        
        // Verify
        Assert.areEqual(1, parsedData.holdingsByPortfolio.size(), 'Should have holdings for 1 portfolio');
        // Check that holdings data is properly parsed
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
        SRV_InvestmentPortfolioAPI.ComprehensivePortfolioData comprehensiveData = 
            SRV_InvestmentPortfolioAPI.parseComprehensiveData(responseData);
        Test.stopTest();
        
        // Verify
        Assert.areEqual(1, comprehensiveData.transactionsByPortfolio.size(), 'Should have transactions for 1 portfolio');
    }
}

