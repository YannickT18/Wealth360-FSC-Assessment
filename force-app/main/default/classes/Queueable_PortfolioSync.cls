/**
 * @description Queueable class for async bulk synchronization of comprehensive portfolio data
 * @author Yannick Kayombo
 * @date 22-11-2025
 */
public without sharing class Queueable_PortfolioSync implements Queueable, Database.AllowsCallouts {
    
    private List<Id> accountIds;
    private Integer batchSize;
    private Integer currentBatch;
    
    /**
     * @description Constructor for syncing comprehensive portfolio data for multiple accounts
     * @param accountIds List of Account IDs to sync
     */
    public Queueable_PortfolioSync(List<Id> accountIds) {
        this.accountIds = accountIds;
        this.batchSize = 50; // Process 50 accounts at a time
        this.currentBatch = 0;
    }
    
    /**
     * @description Execute method called by Queueable framework
     * @param context QueueableContext
     */
    public void execute(QueueableContext context) {
        try {
            // Only comprehensive sync is now supported for optimal performance
            syncPortfolios();
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in Queueable_PortfolioSync: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
            // In production, would log to custom error object or platform event
        }
    }
    
    /**
     * @description Sync all portfolio data (portfolios, holdings, transactions) from external API using single comprehensive call
     */
    private void syncPortfolios() {
        List<FinServ__FinancialAccount__c> financialAccountsToUpsert = 
            new List<FinServ__FinancialAccount__c>();
        List<FinServ__FinancialHolding__c> holdingsToUpsert = 
            new List<FinServ__FinancialHolding__c>();
        List<FinServ__FinancialAccountTransaction__c> transactionsToUpsert = 
            new List<FinServ__FinancialAccountTransaction__c>();
        
        // Process accounts in current batch
        Integer startIndex = currentBatch * batchSize;
        Integer endIndex = Math.min(startIndex + batchSize, accountIds.size());
        List<Id> currentBatchIds = new List<Id>();
        
        for (Integer i = startIndex; i < endIndex; i++) {
            currentBatchIds.add(accountIds[i]);
        }
        
        // Make single comprehensive callout for each account
        for (Id accountId : currentBatchIds) {
            try {
                // Get all data in one call - much more efficient!
                SRV_InvestmentPortfolioAPI.ComprehensivePortfolioData comprehensiveData = 
                    SRV_InvestmentPortfolioAPI.getAllPortfolioDataForSync(accountId);
                
                // Process portfolios
                for (Map<String, Object> portfolioData : comprehensiveData.portfolios) {
                    FinServ__FinancialAccount__c financialAccount = 
                        mapPortfolioToFinancialAccount(portfolioData, accountId);
                    financialAccountsToUpsert.add(financialAccount);
                    
                    String externalPortfolioId = (String)portfolioData.get('portfolioId');
                    
                    // Process holdings for this portfolio
                    if (comprehensiveData.holdingsByPortfolio.containsKey(externalPortfolioId)) {
                        List<Map<String, Object>> holdings = comprehensiveData.holdingsByPortfolio.get(externalPortfolioId);
                        for (Map<String, Object> holdingData : holdings) {
                            FinServ__FinancialHolding__c holding = 
                                mapHoldingToFinancialHolding(holdingData, financialAccount.Id);
                            holdingsToUpsert.add(holding);
                        }
                    }
                    
                    // Process transactions for this portfolio
                    if (comprehensiveData.transactionsByPortfolio.containsKey(externalPortfolioId)) {
                        List<Map<String, Object>> transactions = comprehensiveData.transactionsByPortfolio.get(externalPortfolioId);
                        for (Map<String, Object> transactionData : transactions) {
                            FinServ__FinancialAccountTransaction__c transaction = 
                                mapTransactionToFinancialAccountTransaction(transactionData, financialAccount.Id);
                            transactionsToUpsert.add(transaction);
                        }
                    }
                }
                
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error syncing comprehensive data for account ' + 
                           accountId + ': ' + e.getMessage());
                continue; // Continue with next account
            }
        }
        
        // Bulk upsert all data types
        upsertFinancialData(financialAccountsToUpsert, holdingsToUpsert, transactionsToUpsert);
        
        // Chain next batch if more accounts to process
        if (endIndex < accountIds.size()) {
            currentBatch++;
            if (!Test.isRunningTest()) {
                System.enqueueJob(new Queueable_PortfolioSync(accountIds));
            }
        }
    }
    
    /**
     * @description Helper method to bulk upsert all financial data types
     */
    private void upsertFinancialData(
        List<FinServ__FinancialAccount__c> financialAccounts,
        List<FinServ__FinancialHolding__c> holdings, 
        List<FinServ__FinancialAccountTransaction__c> transactions
    ) {
        // Upsert Financial Accounts first
        if (!financialAccounts.isEmpty()) {
            Database.UpsertResult[] faResults = Database.upsert(
                financialAccounts, 
                FinServ__FinancialAccount__c.ExternalPortfolioId__c,
                false
            );
            logUpsertResults('Financial Account', faResults);
        }
        
        // Upsert Holdings
        if (!holdings.isEmpty()) {
            Database.UpsertResult[] holdingResults = Database.upsert(
                holdings,
                FinServ__FinancialHolding__c.ExternalHoldingId__c,
                false
            );
            logUpsertResults('Financial Holding', holdingResults);
        }
        
        // Upsert Transactions
        if (!transactions.isEmpty()) {
            Database.UpsertResult[] txnResults = Database.upsert(
                transactions,
                FinServ__FinancialAccountTransaction__c.ExternalTransactionId__c,
                false
            );
            logUpsertResults('Financial Transaction', txnResults);
        }
    }
    
    /**
     * @description Helper method to log upsert results
     */
    private void logUpsertResults(String objectType, Database.UpsertResult[] results) {
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                System.debug(LoggingLevel.ERROR, 'Failed to upsert ' + objectType + ': ' + 
                           results[i].getErrors());
            }
        }
    }
    
    /**
     * @description Sync holdings data for existing portfolios
     */
    private void syncHoldings() {
        // Query Financial Accounts with external IDs
        List<FinServ__FinancialAccount__c> financialAccounts = [
            SELECT Id, ExternalPortfolioId__c
            FROM FinServ__FinancialAccount__c
            WHERE ExternalPortfolioId__c != null
            AND Id IN (SELECT FinServ__FinancialAccount__c 
                      FROM FinServ__FinancialHolding__c)
            LIMIT 50
        ];
        
        List<FinServ__FinancialHolding__c> holdingsToUpsert = 
            new List<FinServ__FinancialHolding__c>();
        
        for (FinServ__FinancialAccount__c fa : financialAccounts) {
            try {
                SRV_InvestmentPortfolioAPI.APIResponse response = 
                    SRV_InvestmentPortfolioAPI.getHoldings(fa.ExternalPortfolioId__c);
                
                if (response.success) {
                    List<Map<String, Object>> holdings = 
                        SRV_InvestmentPortfolioAPI.parseHoldings(
                            (Map<String, Object>)response.data
                        );
                    
                    for (Map<String, Object> holdingData : holdings) {
                        FinServ__FinancialHolding__c holding = 
                            mapHoldingToFinancialHolding(holdingData, fa.Id);
                        holdingsToUpsert.add(holding);
                    }
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error syncing holdings for FA ' + 
                           fa.Id + ': ' + e.getMessage());
                continue;
            }
        }
        
        if (!holdingsToUpsert.isEmpty()) {
            Database.UpsertResult[] results = Database.upsert(
                holdingsToUpsert,
                FinServ__FinancialHolding__c.ExternalHoldingId__c,
                false
            );
            
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    System.debug(LoggingLevel.ERROR, 'Failed to upsert Financial Holding: ' + 
                               results[i].getErrors());
                }
            }
        }
    }
    
    /**
     * @description Sync transaction data for existing portfolios
     */
    private void syncTransactions() {
        // Query Financial Accounts with external IDs
        List<FinServ__FinancialAccount__c> financialAccounts = [
            SELECT Id, ExternalPortfolioId__c, LastSyncDate__c
            FROM FinServ__FinancialAccount__c
            WHERE ExternalPortfolioId__c != null
            LIMIT 50
        ];
        
        List<FinServ__FinancialAccountTransaction__c> transactionsToUpsert = 
            new List<FinServ__FinancialAccountTransaction__c>();
        
        Date startDate = System.today().addDays(-90); // Last 90 days
        Date endDate = System.today();
        
        for (FinServ__FinancialAccount__c fa : financialAccounts) {
            try {
                SRV_InvestmentPortfolioAPI.APIResponse response = 
                    SRV_InvestmentPortfolioAPI.getTransactions(
                        fa.ExternalPortfolioId__c, startDate, endDate
                    );
                
                if (response.success) {
                    List<Map<String, Object>> transactions = 
                        SRV_InvestmentPortfolioAPI.parseTransactions(
                            (Map<String, Object>)response.data
                        );
                    
                    for (Map<String, Object> txnData : transactions) {
                        FinServ__FinancialAccountTransaction__c txn = 
                            mapTransactionToFinancialAccountTransaction(txnData, fa.Id);
                        transactionsToUpsert.add(txn);
                    }
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error syncing transactions for FA ' + 
                           fa.Id + ': ' + e.getMessage());
                continue;
            }
        }
        
        if (!transactionsToUpsert.isEmpty()) {
            Database.UpsertResult[] results = Database.upsert(
                transactionsToUpsert,
                FinServ__FinancialAccountTransaction__c.ExternalTransactionId__c,
                false
            );
            
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    System.debug(LoggingLevel.ERROR, 'Failed to upsert Transaction: ' + 
                               results[i].getErrors());
                }
            }
        }
    }
    
    /**
     * @description Map external portfolio data to Financial Account
     */
    private FinServ__FinancialAccount__c mapPortfolioToFinancialAccount(
        Map<String, Object> portfolioData, Id accountId) {
        
        FinServ__FinancialAccount__c fa = new FinServ__FinancialAccount__c();
        fa.ExternalPortfolioId__c = (String)portfolioData.get('portfolioId');
        fa.Name = (String)portfolioData.get('name');
        fa.FinServ__PrimaryOwner__c = accountId;
        fa.FinServ__FinancialAccountType__c = 'Investment';
        fa.FinServ__Status__c = (String)portfolioData.get('status');
        fa.TotalAssetValue__c = (Decimal)portfolioData.get('totalValue');
        fa.LastSyncDate__c = System.now();
        
        return fa;
    }
    
    /**
     * @description Map external holding data to Financial Holding
     */
    private FinServ__FinancialHolding__c mapHoldingToFinancialHolding(
        Map<String, Object> holdingData, Id financialAccountId) {
        
        FinServ__FinancialHolding__c fh = new FinServ__FinancialHolding__c();
        fh.ExternalHoldingId__c = (String)holdingData.get('holdingId');
        fh.FinServ__FinancialAccount__c = financialAccountId;
        fh.Name = (String)holdingData.get('assetName');
        fh.FinServ__AssetCategory__c = (String)holdingData.get('assetCategory');
        fh.FinServ__MarketValue__c  = (Decimal)holdingData.get('MarketValue');
        fh.PercentOfPortfolio__c = (Decimal)holdingData.get('percentOfPortfolio');
        
        return fh;
    }
    
    /**
     * @description Map external transaction data to Financial Account Transaction
     */
    private FinServ__FinancialAccountTransaction__c mapTransactionToFinancialAccountTransaction(
        Map<String, Object> txnData, Id financialAccountId) {
        
        FinServ__FinancialAccountTransaction__c fat = new FinServ__FinancialAccountTransaction__c();
        fat.ExternalTransactionId__c = (String)txnData.get('transactionId');
        fat.FinServ__FinancialAccount__c = financialAccountId;
        fat.FinServ__TransactionType__c = (String)txnData.get('type');
        fat.FinServ__Amount__c = (Decimal)txnData.get('amount');
        fat.FinServ__TransactionStatus__c = (String)txnData.get('status');
        fat.FinServ__Description__c = (String)txnData.get('description');
        
        // Parse date from string
        String dateStr = (String)txnData.get('transactionDate');
        if (dateStr != null) {
            fat.FinServ__TransactionDate__c = Date.valueOf(dateStr);
        }
        
        return fat;
    }
}