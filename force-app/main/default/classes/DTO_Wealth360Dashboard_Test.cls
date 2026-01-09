/**
 * @description Test class for DTO_Wealth360Dashboard data transfer object classes
 * @author Yannick Kayombo
 * @date 22-11-2025
 */
@IsTest
private class DTO_Wealth360Dashboard_Test {
    
    @TestSetup
    static void makeData() {
        // Create test account
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;
        
        // Create Financial Account
        FinServ__FinancialAccount__c finAccount = new FinServ__FinancialAccount__c(
            Name = 'Test Portfolio',
            FinServ__PrimaryOwner__c = testAccount.Id,
            FinServ__FinancialAccountType__c = 'Investment'
        );
        insert finAccount;
        
        // Create Financial Account Transaction
        FinServ__FinancialAccountTransaction__c transaction = new FinServ__FinancialAccountTransaction__c(
            Name = 'Test Transaction',
            FinServ__FinancialAccount__c = finAccount.Id,
            FinServ__TransactionType__c = 'Buy',
            FinServ__Amount__c = 1000.00,
            FinServ__TransactionDate__c = System.today(),
            FinServ__TransactionStatus__c = 'Complete',
            FinServ__Description__c = 'Test purchase'
        );
        insert transaction;
    }
    
    @IsTest
    static void testAssetAllocation() {
        // Test default constructor
        DTO_Wealth360Dashboard.AssetAllocation allocation1 = new DTO_Wealth360Dashboard.AssetAllocation();
        System.assertNotNull(allocation1, 'Default constructor should create instance');
        
        // Test parameterized constructor
        DTO_Wealth360Dashboard.AssetAllocation allocation2 = 
            new DTO_Wealth360Dashboard.AssetAllocation('Stocks', 10000.00, 65.5);
        
        System.assertEquals('Stocks', allocation2.category, 'Category should be set');
        System.assertEquals(10000.00, allocation2.value, 'Value should be set');
        System.assertEquals(65.5, allocation2.percentage, 'Percentage should be set');
    }
    
    @IsTest
    static void testTransactionDataDefaultConstructor() {
        // Test default constructor
        DTO_Wealth360Dashboard.TransactionData txnData = new DTO_Wealth360Dashboard.TransactionData();
        System.assertNotNull(txnData, 'Default constructor should create instance');
    }
    
    @IsTest
    static void testTransactionDataWithSObject() {
        // Get test data
        List<FinServ__FinancialAccountTransaction__c> transactions = [
            SELECT Id, Name, FinServ__TransactionType__c, FinServ__Amount__c,
                   FinServ__TransactionDate__c, FinServ__TransactionStatus__c,
                   FinServ__Description__c, FinServ__FinancialAccount__r.Name
            FROM FinServ__FinancialAccountTransaction__c
            LIMIT 1
        ];
        
        System.assertNotNull(transactions, 'Test transaction should exist');
        System.assertFalse(transactions.isEmpty(), 'Test transactions list should not be empty');
        
        // Test constructor with SObject
        DTO_Wealth360Dashboard.TransactionData txnData = 
            new DTO_Wealth360Dashboard.TransactionData(transactions[0]);
        
        System.assertEquals(transactions[0].Id, txnData.id, 'ID should match');
        System.assertEquals(transactions[0].Name, txnData.name, 'Name should match');
        System.assertEquals(transactions[0].FinServ__TransactionType__c, txnData.type, 'Type should match');
        System.assertEquals(transactions[0].FinServ__Amount__c, txnData.amount, 'Amount should match');
        System.assertEquals(transactions[0].FinServ__TransactionStatus__c, txnData.status, 'Status should match');
        System.assertEquals(transactions[0].FinServ__Description__c, txnData.description, 'Description should match');
        
        // Test date conversion
        if (transactions[0].FinServ__TransactionDate__c != null) {
            System.assertEquals(
                transactions[0].FinServ__TransactionDate__c.date(), 
                txnData.transactionDate, 
                'Transaction date should be converted properly'
            );
        }
    }
    
    @IsTest
    static void testPortfolioSummary() {
        // Test default constructor
        DTO_Wealth360Dashboard.PortfolioSummary summary = new DTO_Wealth360Dashboard.PortfolioSummary();
        
        System.assertNotNull(summary, 'Constructor should create instance');
        System.assertEquals(0, summary.portfolioCount, 'Portfolio count should be 0');
        System.assertEquals(0, summary.holdingsCount, 'Holdings count should be 0');
        System.assertEquals(0, summary.totalValue, 'Total value should be 0');
        System.assertEquals('Ready', summary.status, 'Status should be Ready');
    }
    
    @IsTest
    static void testPortfolioPerformance() {
        // Test default constructor
        DTO_Wealth360Dashboard.PortfolioPerformance perf1 = new DTO_Wealth360Dashboard.PortfolioPerformance();
        System.assertNotNull(perf1, 'Default constructor should create instance');
        
        // Test parameterized constructor - positive change
        DTO_Wealth360Dashboard.PortfolioPerformance perf2 = 
            new DTO_Wealth360Dashboard.PortfolioPerformance('Test Portfolio', 11000.00, 10000.00);
        
        System.assertEquals('Test Portfolio', perf2.portfolioName, 'Portfolio name should be set');
        System.assertEquals(11000.00, perf2.currentValue, 'Current value should be set');
        System.assertEquals(10000.00, perf2.previousValue, 'Previous value should be set');
        System.assertEquals(1000.00, perf2.changeAmount, 'Change amount should be calculated');
        System.assertEquals(10.00, perf2.changePercentage, 'Change percentage should be calculated');
        System.assertEquals('up', perf2.trend, 'Trend should be up');
        
        // Test negative change
        DTO_Wealth360Dashboard.PortfolioPerformance perf3 = 
            new DTO_Wealth360Dashboard.PortfolioPerformance('Test Portfolio 2', 9000.00, 10000.00);
        
        System.assertEquals(-1000.00, perf3.changeAmount, 'Change amount should be negative');
        System.assertEquals(-10.00, perf3.changePercentage, 'Change percentage should be negative');
        System.assertEquals('down', perf3.trend, 'Trend should be down');
        
        // Test neutral change
        DTO_Wealth360Dashboard.PortfolioPerformance perf4 = 
            new DTO_Wealth360Dashboard.PortfolioPerformance('Test Portfolio 3', 10000.00, 10000.00);
        
        System.assertEquals(0, perf4.changeAmount, 'Change amount should be zero');
        System.assertEquals(0, perf4.changePercentage, 'Change percentage should be zero');
        System.assertEquals('neutral', perf4.trend, 'Trend should be neutral');
        
        // Test null values
        DTO_Wealth360Dashboard.PortfolioPerformance perf5 = 
            new DTO_Wealth360Dashboard.PortfolioPerformance('Test Portfolio 4', null, 10000.00);
        
        System.assertEquals(0, perf5.changeAmount, 'Change amount should be zero for null values');
        System.assertEquals(0, perf5.changePercentage, 'Change percentage should be zero for null values');
        System.assertEquals('neutral', perf5.trend, 'Trend should be neutral for null values');
    }
    
    @IsTest
    static void testApiResponseSuccess() {
        // Test success response
        String testMessage = 'Operation completed successfully';
        String testData = 'Test data';
        
        DTO_Wealth360Dashboard.ApiResponse response = 
            DTO_Wealth360Dashboard.ApiResponse.success(testMessage, testData);
        
        System.assertNotNull(response, 'Response should not be null');
        System.assertEquals(true, response.success, 'Success should be true');
        System.assertEquals(testMessage, response.message, 'Message should match');
        System.assertEquals(testData, response.data, 'Data should match');
        System.assertEquals(null, response.errorCode, 'Error code should be null for success');
    }
    
    @IsTest
    static void testApiResponseError() {
        // Test error response
        String testMessage = 'Operation failed';
        String testErrorCode = 'ERR_001';
        
        DTO_Wealth360Dashboard.ApiResponse response = 
            DTO_Wealth360Dashboard.ApiResponse.error(testMessage, testErrorCode);
        
        System.assertNotNull(response, 'Response should not be null');
        System.assertEquals(false, response.success, 'Success should be false');
        System.assertEquals(testMessage, response.message, 'Message should match');
        System.assertEquals(testErrorCode, response.errorCode, 'Error code should match');
        System.assertEquals(null, response.data, 'Data should be null for error');
    }
    
    @IsTest
    static void testApiResponseDefaultConstructor() {
        // Test default constructor
        DTO_Wealth360Dashboard.ApiResponse response = new DTO_Wealth360Dashboard.ApiResponse();
        System.assertNotNull(response, 'Default constructor should create instance');
    }
}
