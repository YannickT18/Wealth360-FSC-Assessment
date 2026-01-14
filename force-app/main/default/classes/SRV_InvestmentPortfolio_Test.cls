/**
 * @description Test class for SRV_InvestmentPortfolio (business logic service)
 * @author Yannick Kayombo
 * @date 22-11-2025
 */

@isTest
private class SRV_InvestmentPortfolio_Test {
    
    @isTest
    static void testFetchAndSyncPortfolioDataSuccess() {
        // Setup
        Account acc = TEST_DataFactory.createAccount('TestClient', true);
        
        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new MOCK_InvestmentPortfolioAPI());
        
        // Test
        Test.startTest();
        SRV_InvestmentPortfolio.SyncResult result = SRV_InvestmentPortfolio.fetchAndSyncPortfolioData(acc.Id);
        Test.stopTest();
        
        // Verify
        Assert.isTrue(result.success, 'Sync should be successful');
        Assert.areEqual('Portfolio data synchronized successfully', result.message, 'Success message should match');
        Assert.isNotNull(result.financialAccountIds, 'Financial account IDs should not be null');
        Assert.isTrue(result.portfoliosSynced >= 0, 'Portfolios synced count should be non-negative');
        Assert.isTrue(result.holdingsSynced >= 0, 'Holdings synced count should be non-negative');
        Assert.isTrue(result.transactionsSynced >= 0, 'Transactions synced count should be non-negative');
    }
    
    @isTest
    static void testSyncComprehensivePortfolioDataWithMockData() {
        // Setup
        Account acc = TEST_DataFactory.createAccount('TestClient', true);
        
        // Create mock data structure using Map<String, Object>
        Map<String, Object> comprehensiveData = new Map<String, Object>();
        
        // Add portfolios list
        List<Object> portfoliosList = new List<Object>();
        Map<String, Object> portfolio = new Map<String, Object>{
            'portfolioId' => 'PORT001',
            'name' => 'Test Portfolio',
            'total_value' => 100000,
            'type' => 'Investment',
            'status' => 'Active'
        };
        portfoliosList.add(portfolio);
        comprehensiveData.put('portfolios', portfoliosList);
        
        // Add holdings by portfolio
        Map<String, Object> holdingsByPortfolio = new Map<String, Object>();
        List<Object> holdingsList = new List<Object>();
        Map<String, Object> holding = new Map<String, Object>{
            'holdingId' => 'HOLD001',
            'asset_name' => 'Test Stock',
            'market_value' => 50000,
            'quantity' => 100,
            'asset_category' => 'Stocks'
        };
        holdingsList.add(holding);
        holdingsByPortfolio.put('PORT001', holdingsList);
        comprehensiveData.put('holdingsByPortfolio', holdingsByPortfolio);
        
        // Add transactions by portfolio
        Map<String, Object> transactionsByPortfolio = new Map<String, Object>();
        List<Object> transactionsList = new List<Object>();
        Map<String, Object> transaction = new Map<String, Object>{
            'transactionId' => 'TXN001',
            'transaction_type' => 'Buy',
            'amount' => 10000,
            'transaction_date' => '2026-01-14',
            'description' => 'Test Purchase'
        };
        transactionsList.add(transaction);
        transactionsByPortfolio.put('PORT001', transactionsList);
        comprehensiveData.put('transactionsByPortfolio', transactionsByPortfolio);
        
        // Test
        Test.startTest();
        SRV_InvestmentPortfolio.SyncResult result = SRV_InvestmentPortfolio.syncComprehensivePortfolioData(acc.Id, comprehensiveData);
        Test.stopTest();
        
        // Verify
        Assert.isTrue(result.success, 'Sync should be successful');
        Assert.isNotNull(result.financialAccountIds, 'Financial account IDs should not be null');
        Assert.areEqual(1, result.portfoliosSynced, 'Should sync 1 portfolio');
        Assert.areEqual(1, result.holdingsSynced, 'Should sync 1 holding');
        Assert.areEqual(1, result.transactionsSynced, 'Should sync 1 transaction');
    }
    
    @isTest
    static void testSyncComprehensivePortfolioDataWithEmptyData() {
        // Setup
        Account acc = TEST_DataFactory.createAccount('TestClient', true);
        
        // Test with empty data
        Map<String, Object> emptyData = new Map<String, Object>{
            'portfolios' => new List<Object>(),
            'holdingsByPortfolio' => new Map<String, Object>(),
            'transactionsByPortfolio' => new Map<String, Object>()
        };
        
        // Test
        Test.startTest();
        SRV_InvestmentPortfolio.SyncResult result = SRV_InvestmentPortfolio.syncComprehensivePortfolioData(acc.Id, emptyData);
        Test.stopTest();
        
        // Verify graceful handling of empty data
        Assert.isFalse(result.success, 'Empty data should result in failure');
        Assert.areEqual(0, result.portfoliosSynced, 'No portfolios should be created');
        Assert.areEqual(0, result.holdingsSynced, 'No holdings should be created');
        Assert.areEqual(0, result.transactionsSynced, 'No transactions should be created');
        Assert.isTrue(result.message.contains('No portfolios'), 'Error message should mention no portfolios');
    }
    
    @isTest
    static void testSyncResultConstructors() {
        Test.startTest();
        
        // Test success constructor
        SRV_InvestmentPortfolio.SyncResult successResult = new SRV_InvestmentPortfolio.SyncResult(true, 'Success', 5, 20, 15);
            
        // Test failure constructor
        SRV_InvestmentPortfolio.SyncResult failureResult = new SRV_InvestmentPortfolio.SyncResult(false, 'Error occurred');
        
        Test.stopTest();
        
        // Verify success result
        Assert.isTrue(successResult.success, 'Success result should be true');
        Assert.areEqual('Success', successResult.message, 'Success message should match');
        Assert.areEqual(5, successResult.portfoliosSynced, 'Portfolio count should match');
        Assert.areEqual(20, successResult.holdingsSynced, 'Holdings count should match');
        Assert.areEqual(15, successResult.transactionsSynced, 'Transactions count should match');
        
        // Verify failure result
        Assert.isFalse(failureResult.success, 'Failure result should be false');
        Assert.areEqual('Error occurred', failureResult.message, 'Error message should match');
        Assert.areEqual(0, failureResult.portfoliosSynced, 'Portfolio count should be zero');
        Assert.areEqual(0, failureResult.holdingsSynced, 'Holdings count should be zero');
        Assert.areEqual(0, failureResult.transactionsSynced, 'Transactions count should be zero');
    }
    
    @isTest
    static void testFetchAndSyncPortfolioDataApiFailure() {
        // Setup mock for API failure
        Test.setMock(HttpCalloutMock.class, new MOCK_InvestmentPortfolioAPI('FAILURE'));
        
        Account acc = TEST_DataFactory.createAccount('TestClient', true);
        
        Test.startTest();
        SRV_InvestmentPortfolio.SyncResult result = SRV_InvestmentPortfolio.fetchAndSyncPortfolioData(acc.Id);
        Test.stopTest();
        
        // Verify error handling
        Assert.isFalse(result.success, 'API failure should result in unsuccessful sync');
        Assert.areEqual(0, result.portfoliosSynced, 'No portfolios should be created on API failure');
        Assert.isNotNull(result.message, 'Error message should be provided');
    }
    
    @isTest
    static void testSyncWithNullData() {
        // Test with null data
        Account acc = TEST_DataFactory.createAccount('TestClient', true);
        
        Test.startTest();
        SRV_InvestmentPortfolio.SyncResult result = SRV_InvestmentPortfolio.syncComprehensivePortfolioData(acc.Id, null);
        Test.stopTest();
        
        // Verify null handling
        Assert.isFalse(result.success, 'Null data should result in failure');
        Assert.isTrue(result.message.contains('Sync failed'), 'Error message should mention failure');
    }
}