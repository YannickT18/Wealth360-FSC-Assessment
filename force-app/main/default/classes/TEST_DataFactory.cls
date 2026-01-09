/**
 * @description Test Data Factory for Wealth360 Assessment
 * @author Wealth360 Assessment
 * @date 2025-11-22
 * Demonstrates:
 * - Test data creation patterns
 * - FSC object relationships
 * - Efficient bulk test data generation
 */
@isTest
public class TEST_DataFactory {
    
    /**
     * @description Create test Account (Person Account for FSC)
     */
    public static Account createAccount(String lastName, Boolean doInsert) {
        Account acc = new Account(
            FirstName = 'Test',
            LastName = lastName,
            PersonEmail = lastName.toLowerCase() + '@test.com'
        );
        
        if (doInsert) {
            insert acc;
        }
        
        return acc;
    }
    
    /**
     * @description Create multiple test Accounts
     */
    public static List<Account> createAccounts(Integer count, Boolean doInsert) {
        List<Account> accounts = new List<Account>();
        
        for (Integer i = 0; i < count; i++) {
            accounts.add(createAccount('Client' + i, false));
        }
        
        if (doInsert) {
            insert accounts;
        }
        
        return accounts;
    }
    
    /**
     * @description Create Financial Account
     */
    public static FinServ__FinancialAccount__c createFinancialAccount(
        Id accountId, String name, String externalId, Decimal totalValue, Boolean doInsert) {
        
        FinServ__FinancialAccount__c fa = new FinServ__FinancialAccount__c(
            Name = name,
            FinServ__PrimaryOwner__c = accountId,
            FinServ__FinancialAccountType__c = 'Investment',
            FinServ__Status__c = 'Active',
            ExternalPortfolioId__c = externalId,
            TotalAssetValue__c = totalValue,
            LastSyncDate__c = System.now()
        );
        
        if (doInsert) {
            insert fa;
        }
        
        return fa;
    }
    
    /**
     * @description Create multiple Financial Accounts
     */
    public static List<FinServ__FinancialAccount__c> createFinancialAccounts(
        Id accountId, Integer count, Boolean doInsert) {
        
        List<FinServ__FinancialAccount__c> financialAccounts = 
            new List<FinServ__FinancialAccount__c>();
        
        for (Integer i = 0; i < count; i++) {
            financialAccounts.add(createFinancialAccount(
                accountId,
                'Test Portfolio ' + i,
                'PORT-00' + i,
                100000.00 * (i + 1),
                false
            ));
        }
        
        if (doInsert) {
            insert financialAccounts;
        }
        
        return financialAccounts;
    }
    
    /**
     * @description Create Financial Holding
     */
    public static FinServ__FinancialHolding__c createFinancialHolding(
        Id financialAccountId, String assetCategory, String assetName, 
        Decimal value, Decimal percentage, Boolean doInsert) {
        
        FinServ__FinancialHolding__c fh = new FinServ__FinancialHolding__c(
            FinServ__FinancialAccount__c = financialAccountId,
            Name = assetName,
            FinServ__AssetCategory__c = assetCategory,
            FinServ__MarketValue__c = value,
            PercentOfPortfolio__c = percentage,
            ExternalHoldingId__c = 'HOLD-' + String.valueOf(Math.random()).substring(2, 8)
        );
        
        if (doInsert) {
            insert fh;
        }
        
        return fh;
    }
    
    /**
     * @description Create multiple Financial Holdings for asset allocation
     */
    public static List<FinServ__FinancialHolding__c> createAssetAllocationHoldings(
        Id financialAccountId, Boolean doInsert) {
        
        List<FinServ__FinancialHolding__c> holdings = new List<FinServ__FinancialHolding__c>{
            createFinancialHolding(financialAccountId, 'Stocks', 'US Equities', 350000, 46.67, false),
            createFinancialHolding(financialAccountId, 'Bonds', 'US Treasury Bonds', 225000, 30.00, false),
            createFinancialHolding(financialAccountId, 'Cash', 'Money Market', 100000, 13.33, false),
            createFinancialHolding(financialAccountId, 'Stocks', 'International Equities', 75000, 10.00, false)
        };
        
        if (doInsert) {
            insert holdings;
        }
        
        return holdings;
    }
    
    /**
     * @description Create Financial Account Transaction
     */
    public static FinServ__FinancialAccountTransaction__c createTransaction(
        Id financialAccountId, String type, Decimal amount, Date txnDate, Boolean doInsert) {
        
        FinServ__FinancialAccountTransaction__c txn = 
            new FinServ__FinancialAccountTransaction__c(
                FinServ__FinancialAccount__c = financialAccountId,
                FinServ__TransactionType__c = type,
                FinServ__Amount__c = amount,
                FinServ__TransactionDate__c = txnDate,
                FinServ__TransactionStatus__c = 'Completed',
                FinServ__Description__c = type + ' transaction',
                ExternalTransactionId__c = 'TXN-' + String.valueOf(Math.random()).substring(2, 8)
            );
        
        if (doInsert) {
            insert txn;
        }
        
        return txn;
    }
    
    /**
     * @description Create multiple transactions
     */
    public static List<FinServ__FinancialAccountTransaction__c> createTransactions(
        Id financialAccountId, Integer count, Boolean doInsert) {
        
        List<FinServ__FinancialAccountTransaction__c> transactions = 
            new List<FinServ__FinancialAccountTransaction__c>();
        
        List<String> types = new List<String>{ 'Buy', 'Sell', 'Dividend', 'Interest' };
        
        for (Integer i = 0; i < count; i++) {
            String type = types[Math.mod(i, types.size())];
            Decimal amount = type == 'Sell' ? -5000.00 : 5000.00;
            Date txnDate = System.today().addDays(-(count - i));
            
            transactions.add(createTransaction(
                financialAccountId, type, amount, txnDate, false
            ));
        }
        
        if (doInsert) {
            insert transactions;
        }
        
        return transactions;
    }
}
