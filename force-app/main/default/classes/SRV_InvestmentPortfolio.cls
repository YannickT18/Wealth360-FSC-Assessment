/**
 * @description Investment portfolio service for business logic and data synchronization
 * @author Yannick Kayombo
 * @date 22-11-2025
 */
public without sharing class SRV_InvestmentPortfolio {
    
    /**
     * @description Fetch and sync portfolio data from API
     * @param accountId Account ID to sync data for
     * @return SyncResult indicating success/failure and details
     */
    public static SyncResult fetchAndSyncPortfolioData(Id accountId) {
        try {
            //API Call - handled by API service
            SRV_InvestmentPortfolioAPI.APIResponse response = SRV_InvestmentPortfolioAPI.getComprehensivePortfolioData(accountId, true, true, 30);
            
            if (response.success && response.data != null) {
                //Business Logic - handled by this class
                return syncComprehensivePortfolioData(accountId, (Map<String, Object>)response.data);
            } else {
                String errorMessage = 'Failed to fetch portfolio data from API';
                if (!String.isBlank(response.errorMessage)) {
                    errorMessage += ': ' + response.errorMessage;
                }
                return new SyncResult(false, errorMessage, null);
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in fetchAndSyncPortfolioData: ' + e.getMessage());
            return new SyncResult(false, 'Sync failed: ' + e.getMessage(), null);
        }
    }

    /**
     * @description Sync complete portfolio data from API response
     * @param accountId Account ID to sync data for
     * @param comprehensiveData API response data as Map
     * @return SyncResult with sync details
     */
    public static SyncResult syncComprehensivePortfolioData(Id accountId, Map<String, Object> comprehensiveData) {
        try {
            Integer portfoliosSynced = 0;
            Integer holdingsSynced = 0;
            Integer transactionsSynced = 0;
            
            // Extract portfolios from API response
            List<Object> portfoliosList = (List<Object>)comprehensiveData.get('portfolios');
            if (portfoliosList != null) {
                // Convert to List<Map<String, Object>>
                List<Map<String, Object>> portfolios = new List<Map<String, Object>>();
                for (Object portfolio : portfoliosList) {
                    portfolios.add((Map<String, Object>)portfolio);
                }
                
                // Sync portfolios first to get Financial Account IDs
                List<Id> financialAccountIds = upsertPortfolios(accountId, portfolios);
                portfoliosSynced = portfolios.size();
                
                // Sync holdings and transactions for the portfolios
                if (!financialAccountIds.isEmpty()) {
                    holdingsSynced = upsertHoldings(financialAccountIds, comprehensiveData);
                    transactionsSynced = upsertTransactions(financialAccountIds, comprehensiveData);
                }
                
                return new SyncResult(true, 'Portfolio data synchronized successfully', financialAccountIds, portfoliosSynced, holdingsSynced, transactionsSynced);
            } else {
                return new SyncResult(false, 'No portfolios found in API response', null);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in syncComprehensivePortfolioData: ' + e.getMessage());
            return new SyncResult(false, 'Sync failed: ' + e.getMessage(), null);
        }
    }

    /**
     * @description Custom exception for sync operations
     */
    public class SyncException extends Exception {}

    /**
     * @description Sync result wrapper class
     */
    public class SyncResult {
        public Boolean success;
        public String message;
        public List<Id> financialAccountIds;
        public Integer portfoliosSynced;
        public Integer holdingsSynced;
        public Integer transactionsSynced;
        
        public SyncResult() {
            this.success = false;
            this.portfoliosSynced = 0;
            this.holdingsSynced = 0;
            this.transactionsSynced = 0;
        }
        
        public SyncResult(Boolean success, String message, List<Id> financialAccountIds) {
            this();
            this.success = success;
            this.message = message;
            this.financialAccountIds = financialAccountIds;
        }
        
        public SyncResult(Boolean success, String message, List<Id> financialAccountIds, Integer portfoliosSynced, Integer holdingsSynced, Integer transactionsSynced) {
            this.success = success;
            this.message = message;
            this.financialAccountIds = financialAccountIds;
            this.portfoliosSynced = portfoliosSynced;
            this.holdingsSynced = holdingsSynced;
            this.transactionsSynced = transactionsSynced;
        }
    }

    /**
     * @description Upsert portfolio data and return financial account IDs
     * @param accountId Account ID for the primary owner
     * @param portfolios Portfolio data from API
     * @return List of Financial Account IDs
     */
    private static List<Id> upsertPortfolios(Id accountId, List<Map<String, Object>> portfolios) {
        List<FinServ__FinancialAccount__c> financialAccountsToUpsert = new List<FinServ__FinancialAccount__c>();
        
        // Map portfolio data to Financial Account records
        for (Map<String, Object> portfolioData : portfolios) {
            FinServ__FinancialAccount__c fa = new FinServ__FinancialAccount__c();
            
            // Set standard fields
            fa.FinServ__PrimaryOwner__c = accountId;
            fa.LastSyncDate__c = System.now();
            
            // Apply basic field mapping
            if (portfolioData.containsKey('portfolioId')) {
                fa.ExternalPortfolioId__c = String.valueOf(portfolioData.get('portfolioId'));
            }
            if (portfolioData.containsKey('name')) {
                fa.Name = String.valueOf(portfolioData.get('name'));
            }
            if (portfolioData.containsKey('total_value')) {
                Decimal totalValue = Decimal.valueOf(String.valueOf(portfolioData.get('total_value')));
                fa.FinServ__Balance__c = totalValue;
                fa.TotalAssetValue__c = totalValue;
            }
            if (portfolioData.containsKey('type')) {
                fa.FinServ__FinancialAccountType__c = String.valueOf(portfolioData.get('type'));
            }
            if (portfolioData.containsKey('status')) {
                fa.FinServ__Status__c = String.valueOf(portfolioData.get('status'));
            }
            
            financialAccountsToUpsert.add(fa);
        }
        
        // Upsert and handle results
        Database.UpsertResult[] results = Database.upsert(
            financialAccountsToUpsert,
            FinServ__FinancialAccount__c.ExternalPortfolioId__c,
            false
        );
        
        return handleUpsertResults(results, financialAccountsToUpsert, 'portfolios');
    }

    /**
     * @description Upsert holdings data for financial accounts
     * @param financialAccountIds List of Financial Account IDs
     * @param comprehensiveData Complete portfolio data
     * @return Number of holdings synced
     */
    private static Integer upsertHoldings(List<Id> financialAccountIds, Map<String, Object> comprehensiveData) {
        List<FinServ__FinancialHolding__c> holdingsToUpsert = new List<FinServ__FinancialHolding__c>();
        
        // Query to get external portfolio IDs for the financial accounts
        Map<String, Id> externalIdToFAId = getExternalIdToFinancialAccountMapping(financialAccountIds);
        
        // Extract holdings from the payload structure
        Map<String, Object> holdingsByPortfolio = (Map<String, Object>)comprehensiveData.get('holdingsByPortfolio');
        if (holdingsByPortfolio != null) {
            for (String externalPortfolioId : holdingsByPortfolio.keySet()) {
                Id financialAccountId = externalIdToFAId.get(externalPortfolioId);
                
                if (financialAccountId != null) {
                    List<Object> holdingsList = (List<Object>)holdingsByPortfolio.get(externalPortfolioId);
                    
                    for (Object holdingObj : holdingsList) {
                        Map<String, Object> holdingData = (Map<String, Object>)holdingObj;
                        FinServ__FinancialHolding__c fh = new FinServ__FinancialHolding__c();
                        fh.FinServ__FinancialAccount__c = financialAccountId;
                        
                        // Apply basic field mapping
                        if (holdingData.containsKey('holdingId')) {
                            fh.ExternalHoldingId__c = String.valueOf(holdingData.get('holdingId'));
                        }
                        if (holdingData.containsKey('asset_name')) {
                            fh.Name = String.valueOf(holdingData.get('asset_name'));
                        }
                        if (holdingData.containsKey('market_value')) {
                            fh.FinServ__MarketValue__c = Decimal.valueOf(String.valueOf(holdingData.get('market_value')));
                        }
                        if (holdingData.containsKey('quantity')) {
                            fh.FinServ__Shares__c = Decimal.valueOf(String.valueOf(holdingData.get('quantity')));
                        }
                        if (holdingData.containsKey('asset_category')) {
                            fh.FinServ__AssetCategory__c = String.valueOf(holdingData.get('asset_category'));
                        }
                        
                        holdingsToUpsert.add(fh);
                    }
                }
            }
        }
        
        // Upsert holdings if any exist
        if (!holdingsToUpsert.isEmpty()) {
            Database.UpsertResult[] results = Database.upsert(
                holdingsToUpsert,
                FinServ__FinancialHolding__c.ExternalHoldingId__c,
                false
            );
            handleUpsertResults(results, holdingsToUpsert, 'holdings');
        }
        
        return holdingsToUpsert.size();
    }

    /**
     * @description Upsert transaction data for financial accounts
     * @param financialAccountIds List of Financial Account IDs
     * @param comprehensiveData Complete portfolio data
     * @return Number of transactions synced
     */
    private static Integer upsertTransactions(List<Id> financialAccountIds, Map<String, Object> comprehensiveData) {
        List<FinServ__FinancialAccountTransaction__c> transactionsToUpsert = new List<FinServ__FinancialAccountTransaction__c>();
        
        // Get mapping of external IDs to Financial Account IDs
        Map<String, Id> externalIdToFAId = getExternalIdToFinancialAccountMapping(financialAccountIds);
        
        // Extract transactions from the payload structure
        Map<String, Object> transactionsByPortfolio = (Map<String, Object>)comprehensiveData.get('transactionsByPortfolio');
        if (transactionsByPortfolio != null) {
            for (String externalPortfolioId : transactionsByPortfolio.keySet()) {
                Id financialAccountId = externalIdToFAId.get(externalPortfolioId);
                
                if (financialAccountId != null) {
                    List<Object> transactionsList = (List<Object>)transactionsByPortfolio.get(externalPortfolioId);
                    
                    for (Object transactionObj : transactionsList) {
                        Map<String, Object> txnData = (Map<String, Object>)transactionObj;
                        FinServ__FinancialAccountTransaction__c fat = new FinServ__FinancialAccountTransaction__c();
                        fat.FinServ__FinancialAccount__c = financialAccountId;
                        
                        // Apply basic field mapping
                        if (txnData.containsKey('transactionId')) {
                            fat.ExternalTransactionId__c = String.valueOf(txnData.get('transactionId'));
                        }
                        if (txnData.containsKey('transaction_type')) {
                            fat.FinServ__TransactionType__c = String.valueOf(txnData.get('transaction_type'));
                        }
                        if (txnData.containsKey('amount')) {
                            fat.FinServ__Amount__c = Decimal.valueOf(String.valueOf(txnData.get('amount')));
                        }
                        if (txnData.containsKey('transaction_date')) {
                            String dateStr = String.valueOf(txnData.get('transaction_date'));
                            try {
                                fat.FinServ__TransactionDate__c = Date.valueOf(dateStr);
                            } catch (Exception e) {
                                fat.FinServ__TransactionDate__c = System.today();
                                System.debug(LoggingLevel.WARN, 'Could not parse transaction_date: ' + dateStr);
                            }
                        } else {
                            fat.FinServ__TransactionDate__c = System.today();
                        }
                        if (txnData.containsKey('description')) {
                            fat.FinServ__Description__c = String.valueOf(txnData.get('description'));
                        }
                        
                        transactionsToUpsert.add(fat);
                    }
                }
            }
        }
        
        // Upsert transactions if any exist
        if (!transactionsToUpsert.isEmpty()) {
            Database.UpsertResult[] results = Database.upsert(
                transactionsToUpsert,
                FinServ__FinancialAccountTransaction__c.ExternalTransactionId__c,
                false
            );
            handleUpsertResults(results, transactionsToUpsert, 'transactions');
        }
        
        return transactionsToUpsert.size();
    }

    /**
     * @description Get mapping of external portfolio IDs to Financial Account IDs
     * @param financialAccountIds List of Financial Account IDs
     * @return Map of External ID to Financial Account ID
     */
    private static Map<String, Id> getExternalIdToFinancialAccountMapping(List<Id> financialAccountIds) {
        Map<String, Id> externalIdToFAId = new Map<String, Id>();
        
        List<FinServ__FinancialAccount__c> financialAccounts = [
            SELECT Id, ExternalPortfolioId__c
            FROM FinServ__FinancialAccount__c
            WHERE Id IN :financialAccountIds
        ];
        
        for (FinServ__FinancialAccount__c fa : financialAccounts) {
            if (fa.ExternalPortfolioId__c != null) {
                externalIdToFAId.put(fa.ExternalPortfolioId__c, fa.Id);
            }
        }
        
        return externalIdToFAId;
    }

    /**
     * @description Handle upsert results and return successful IDs
     * @param results Database upsert results
     * @param records List of records that were upserted
     * @param recordType Type of record for error messages
     * @return List of successful record IDs
     */
    private static List<Id> handleUpsertResults(Database.UpsertResult[] results, List<SObject> records, String recordType) {
        List<String> errors = new List<String>();
        List<Id> successfulIds = new List<Id>();
        
        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                successfulIds.add(results[i].getId());
            } else {
                for (Database.Error err : results[i].getErrors()) {
                    String errorMsg = recordType + ' record: ' + err.getMessage();
                    errors.add(errorMsg);
                    System.debug(LoggingLevel.ERROR, 'ERROR: ' + errorMsg);
                }
            }
        }
        
        // Log warnings for partial failures but don't throw exceptions
        if (!errors.isEmpty()) {
            System.debug(LoggingLevel.WARN, 'Partial ' + recordType + ' sync completed with errors: ' + String.join(errors, '; '));
        }
        
        return successfulIds;
    }
}