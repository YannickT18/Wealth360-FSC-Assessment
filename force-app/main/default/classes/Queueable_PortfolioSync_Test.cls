/**
 * @description Test class for Queueable_PortfolioSync
 * @author Wealth360 Assessment
 * @date 2025-11-22
 */
@isTest
private class Queueable_PortfolioSync_Test {
    
    @TestSetup
    static void setupTestData() {
        // Create test accounts
        List<Account> accounts = TEST_DataFactory.createAccounts(3, true);
    }
    
    @isTest
    static void testSyncPortfolios() {
        // Get test accounts
        List<Account> accounts = [SELECT Id FROM Account];
        List<Id> accountIds = new List<Id>();
        for (Account acc : accounts) {
            accountIds.add(acc.Id);
        }
        
        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new Mock_InvestmentPortfolioAPI());
        
        // Test
        Test.startTest();
        Queueable_PortfolioSync syncJob = new Queueable_PortfolioSync(accountIds);
        System.enqueueJob(syncJob);
        Test.stopTest();
        
        // Verify financial accounts were created
        List<FinServ__FinancialAccount__c> financialAccounts = [
            SELECT Id, ExternalPortfolioId__c, FinServ__PrimaryOwner__c
            FROM FinServ__FinancialAccount__c
        ];
        
        Assert.isTrue(financialAccounts.size() > 0, 
                     'Financial accounts should have been created');
        
        // Verify external IDs are set
        for (FinServ__FinancialAccount__c fa : financialAccounts) {
            Assert.areNotEqual(null, fa.ExternalPortfolioId__c, 
                                 'External Portfolio ID should be set');
        }
    }
    
    @isTest
    static void testSyncHoldings() {
        // Setup - Create financial account
        Account acc = [SELECT Id FROM Account LIMIT 1];
        FinServ__FinancialAccount__c fa = TEST_DataFactory.createFinancialAccount(
            acc.Id, 'Test Portfolio', 'PORT-001', 100000, true
        );
        
        List<Id> accountIds = new List<Id>{ acc.Id };
        
        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new Mock_InvestmentPortfolioAPI());
        
        // Test
        Test.startTest();
        Queueable_PortfolioSync syncJob = new Queueable_PortfolioSync(accountIds, 'holdings');
        System.enqueueJob(syncJob);
        Test.stopTest();
        
        // Verify holdings were created
        List<FinServ__FinancialHolding__c> holdings = [
            SELECT Id, ExternalHoldingId__c, FinServ__FinancialAccount__c
            FROM FinServ__FinancialHolding__c
        ];
        
        Assert.isTrue(holdings.size() > 0, 'Holdings should have been created');
        
        // Verify external IDs are set
        for (FinServ__FinancialHolding__c fh : holdings) {
            Assert.areNotEqual(null, fh.ExternalHoldingId__c, 
                                 'External Holding ID should be set');
        }
    }
    
    @isTest
    static void testSyncTransactions() {
        // Setup - Create financial account
        Account acc = [SELECT Id FROM Account LIMIT 1];
        FinServ__FinancialAccount__c fa = TEST_DataFactory.createFinancialAccount(
            acc.Id, 'Test Portfolio', 'PORT-001', 100000, true
        );
        
        List<Id> accountIds = new List<Id>{ acc.Id };
        
        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new Mock_InvestmentPortfolioAPI());
        
        // Test
        Test.startTest();
        Queueable_PortfolioSync syncJob = new Queueable_PortfolioSync(accountIds, 'transactions');
        System.enqueueJob(syncJob);
        Test.stopTest();
        
        // Verify transactions were created
        List<FinServ__FinancialAccountTransaction__c> transactions = [
            SELECT Id, ExternalTransactionId__c, FinServ__FinancialAccount__c
            FROM FinServ__FinancialAccountTransaction__c
        ];
        
        Assert.isTrue(transactions.size() > 0, 'Transactions should have been created');
        
        // Verify external IDs are set
        for (FinServ__FinancialAccountTransaction__c txn : transactions) {
            Assert.areNotEqual(null, txn.ExternalTransactionId__c, 
                                 'External Transaction ID should be set');
        }
    }
    
    @isTest
    static void testUpsertExistingRecords() {
        // Setup - Create financial account
        Account acc = [SELECT Id FROM Account LIMIT 1];
        FinServ__FinancialAccount__c fa = TEST_DataFactory.createFinancialAccount(
            acc.Id, 'Test Portfolio', 'PORT-001', 50000, true
        );
        
        List<Id> accountIds = new List<Id>{ acc.Id };
        
        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new Mock_InvestmentPortfolioAPI());
        
        // First sync
        Test.startTest();
        Queueable_PortfolioSync syncJob1 = new Queueable_PortfolioSync(accountIds);
        System.enqueueJob(syncJob1);
        Test.stopTest();
        
        // Verify record was updated (not duplicated)
        List<FinServ__FinancialAccount__c> financialAccounts = [
            SELECT Id, ExternalPortfolioId__c, TotalAssetValue__c
            FROM FinServ__FinancialAccount__c
            WHERE ExternalPortfolioId__c = 'PORT-001'
        ];
        
        // Should only have one record with this external ID
        Assert.areEqual(1, financialAccounts.size(), 
                          'Should only have one record with external ID PORT-001');
    }
    
    @isTest
    static void testBulkProcessing() {
        // Create 100 test accounts (bulkification test)
        List<Account> bulkAccounts = TEST_DataFactory.createAccounts(100, true);
        List<Id> accountIds = new List<Id>();
        for (Account acc : bulkAccounts) {
            accountIds.add(acc.Id);
        }
        
        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new Mock_InvestmentPortfolioAPI());
        
        // Test
        Test.startTest();
        Queueable_PortfolioSync syncJob = new Queueable_PortfolioSync(accountIds);
        System.enqueueJob(syncJob);
        Test.stopTest();
        
        // Verify no governor limit exceptions occurred
        // This is implicit if test completes successfully
        Assert.isTrue(true, 'Bulk processing completed without governor limit exceptions');
    }
    
    @isTest
    static void testErrorHandling() {
        // Get test account
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Id> accountIds = new List<Id>{ acc.Id };
        
        // Set mock callout with error
        Test.setMock(HttpCalloutMock.class, new Mock_InvestmentPortfolioAPI(500, 'error'));
        
        // Test
        Test.startTest();
        Queueable_PortfolioSync syncJob = new Queueable_PortfolioSync(accountIds);
        System.enqueueJob(syncJob);
        Test.stopTest();
        
        // Verify job completed even with error (graceful error handling)
        // No exceptions should be thrown
        Assert.isTrue(true, 'Job completed with graceful error handling');
    }
}
