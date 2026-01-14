/**
 * @description Test class for SRV_InvestmentPortfolioAPI (API service)
 * @author Yannick Kayombo
 * @date 22-11-2025
 */

@isTest
private class SRV_InvestmentPortfolioAPI_Test {
    
    @isTest
    static void testGetComprehensivePortfolioDataSuccess() {
        // Setup
        Account acc = TEST_DataFactory.createAccount('TestClient', true);
        
        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new Mock_InvestmentPortfolioAPI());
        
        // Test
        Test.startTest();
        SRV_InvestmentPortfolioAPI.APIResponse response = SRV_InvestmentPortfolioAPI.getComprehensivePortfolioData(acc.Id, true, true, 30);
        Test.stopTest();
        
        // Verify
        Assert.isTrue(response.success, 'Response should be successful');
        Assert.areEqual(200, response.statusCode, 'Status code should be 200');
        Assert.isNotNull(response.data, 'Response data should not be null');
        
        // Verify data structure
        Map<String, Object> responseData = (Map<String, Object>)response.data;
        Assert.isTrue(responseData.containsKey('portfolios'), 'Response should contain portfolios');
        Assert.isTrue(responseData.containsKey('holdingsByPortfolio'), 'Response should contain holdings');
        Assert.isTrue(responseData.containsKey('transactionsByPortfolio'), 'Response should contain transactions');
    }
    
    @isTest
    static void testGetAllPortfolioDataForSync() {
        // Setup
        Account acc = TEST_DataFactory.createAccount('TestClient', true);
        
        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new MOCK_InvestmentPortfolioAPI());
        
        // Test
        Test.startTest();
        SRV_InvestmentPortfolioAPI.ComprehensivePortfolioData data = 
            SRV_InvestmentPortfolioAPI.getAllPortfolioDataForSync(acc.Id);
        Test.stopTest();
        
        // Verify
        Assert.isNotNull(data, 'Data should not be null');
        Assert.isNotNull(data.portfolios, 'Portfolios list should not be null');
        Assert.isNotNull(data.holdingsByPortfolio, 'Holdings map should not be null');
        Assert.isNotNull(data.transactionsByPortfolio, 'Transactions map should not be null');
    }
    
    @isTest
    static void testParseComprehensiveData() {
        // Setup - create mock API response data
        Map<String, Object> mockResponseData = new Map<String, Object>{
            'portfolios' => new List<Object>{
                new Map<String, Object>{
                    'portfolioId' => 'PORT001',
                    'name' => 'Test Portfolio',
                    'total_value' => 100000
                }
            },
            'holdingsByPortfolio' => new Map<String, Object>{
                'PORT001' => new List<Object>{
                    new Map<String, Object>{
                        'holdingId' => 'HOLD001',
                        'asset_name' => 'Test Stock',
                        'market_value' => 50000
                    }
                }
            },
            'transactionsByPortfolio' => new Map<String, Object>{
                'PORT001' => new List<Object>{
                    new Map<String, Object>{
                        'transactionId' => 'TXN001',
                        'transaction_type' => 'Buy',
                        'amount' => 10000
                    }
                }
            }
        };
        
        // Test
        Test.startTest();
        SRV_InvestmentPortfolioAPI.ComprehensivePortfolioData result = SRV_InvestmentPortfolioAPI.parseComprehensiveData(mockResponseData);
        Test.stopTest();
        
        // Verify
        Assert.areEqual(1, result.portfolios.size(), 'Should have 1 portfolio');
        Assert.areEqual(1, result.holdingsByPortfolio.size(), 'Should have holdings for 1 portfolio');
        Assert.areEqual(1, result.transactionsByPortfolio.size(), 'Should have transactions for 1 portfolio');
        
        // Verify portfolio data
        Map<String, Object> portfolio = result.portfolios[0];
        Assert.areEqual('PORT001', portfolio.get('portfolioId'), 'Portfolio ID should match');
        Assert.areEqual('Test Portfolio', portfolio.get('name'), 'Portfolio name should match');
        
        // Verify holdings data
        List<Map<String, Object>> holdings = result.holdingsByPortfolio.get('PORT001');
        Assert.areEqual(1, holdings.size(), 'Should have 1 holding');
        Assert.areEqual('HOLD001', holdings[0].get('holdingId'), 'Holding ID should match');
        
        // Verify transactions data
        List<Map<String, Object>> transactions = result.transactionsByPortfolio.get('PORT001');
        Assert.areEqual(1, transactions.size(), 'Should have 1 transaction');
        Assert.areEqual('TXN001', transactions[0].get('transactionId'), 'Transaction ID should match');
    }
    
    @isTest
    static void testAPIResponseClass() {

        SRV_InvestmentPortfolioAPI.APIResponse successResponse =   new SRV_InvestmentPortfolioAPI.APIResponse(true, (Object)'test data', 200);
        Assert.isTrue(successResponse.success, 'Success should be true');
        Assert.areEqual('test data', successResponse.data, 'Data should match');
        Assert.areEqual(200, successResponse.statusCode, 'Status code should match');
        Assert.isNull(successResponse.errorMessage, 'Error message should be null for success');
        
        // Test error constructor
        SRV_InvestmentPortfolioAPI.APIResponse errorResponse = 
            new SRV_InvestmentPortfolioAPI.APIResponse(false, 'Error occurred', 500);
        Assert.isFalse(errorResponse.success, 'Success should be false');
        Assert.areEqual('Error occurred', errorResponse.errorMessage, 'Error message should match');
        Assert.areEqual(500, errorResponse.statusCode, 'Status code should match');
        Assert.isNull(errorResponse.data, 'Data should be null for error response');
    }

    @isTest
    static void testComprehensivePortfolioDataClass() {
        // Test constructor
        SRV_InvestmentPortfolioAPI.ComprehensivePortfolioData data = new SRV_InvestmentPortfolioAPI.ComprehensivePortfolioData();
        
        // Verify initialization
        Assert.isNotNull(data.portfolios, 'Portfolios list should be initialized');
        Assert.isNotNull(data.holdingsByPortfolio, 'Holdings map should be initialized');
        Assert.isNotNull(data.transactionsByPortfolio, 'Transactions map should be initialized');
        Assert.areEqual(0, data.portfolios.size(), 'Portfolios list should be empty');
        Assert.areEqual(0, data.holdingsByPortfolio.size(), 'Holdings map should be empty');
        Assert.areEqual(0, data.transactionsByPortfolio.size(), 'Transactions map should be empty');
    }
    
    @isTest
    static void testErrorScenarios() {
        // Setup
        Account acc = TEST_DataFactory.createAccount('TestClient', true);
        
        // Test rate limit error
        Test.setMock(HttpCalloutMock.class, new MOCK_InvestmentPortfolioAPI(429, 'error'));
        
        Test.startTest();
        SRV_InvestmentPortfolioAPI.ComprehensivePortfolioData data = SRV_InvestmentPortfolioAPI.getAllPortfolioDataForSync(acc.Id);
        Test.stopTest();
        
        // Verify error handling - should return empty data structure
        Assert.isNotNull(data, 'Data should not be null even on error');
        Assert.areEqual(0, data.portfolios.size(), 'Should return empty portfolios on error');
    }
}