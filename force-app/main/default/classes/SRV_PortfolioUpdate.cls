/**
 * @description Service class to handle portfolio data synchronization with metadata-driven field mapping
 * @author Wealth360 Team
 * @date 2026
 */
public with sharing class SRV_PortfolioUpdate {
    
    /**
     * @description Sync complete portfolio data from API response using metadata mappings
     * @param accountId Account ID to sync data for
     * @param comprehensiveData API response data
     */
    public static void syncComprehensivePortfolioData(Id accountId, SRV_InvestmentPortfolioAPI.ComprehensivePortfolioData comprehensiveData) {
        // Sync portfolios first to get Financial Account IDs
        List<Id> financialAccountIds = upsertPortfolios(accountId, comprehensiveData.portfolios);
        
        // Sync holdings and transactions for the portfolios
        upsertHoldings(financialAccountIds, comprehensiveData);
        upsertTransactions(financialAccountIds, comprehensiveData);
    }
    
    /**
     * @description Upsert portfolio data and return financial account IDs using metadata mappings
     * @param accountId Account ID  
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
            
            // Apply metadata mappings for Portfolio
            applyFieldMappings('Portfolio', portfolioData, fa);
            
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
     * @description Upsert holdings data for financial accounts using metadata mappings
     * @param financialAccountIds List of Financial Account IDs
     * @param comprehensiveData Complete portfolio data
     */
    private static void upsertHoldings(List<Id> financialAccountIds, SRV_InvestmentPortfolioAPI.ComprehensivePortfolioData comprehensiveData) {
        List<FinServ__FinancialHolding__c> holdingsToUpsert = new List<FinServ__FinancialHolding__c>();
        
        // Query to get external portfolio IDs for the financial accounts
        Map<String, Id> externalIdToFAId = getExternalIdToFinancialAccountMapping(financialAccountIds);
        
        // Process holdings by portfolio
        for (String externalPortfolioId : comprehensiveData.holdingsByPortfolio.keySet()) {
            Id financialAccountId = externalIdToFAId.get(externalPortfolioId);
            if (financialAccountId != null) {
                List<Map<String, Object>> holdings = comprehensiveData.holdingsByPortfolio.get(externalPortfolioId);
                
                for (Map<String, Object> holdingData : holdings) {
                    FinServ__FinancialHolding__c fh = new FinServ__FinancialHolding__c();
                    fh.FinServ__FinancialAccount__c = financialAccountId;
                    
                    // Apply metadata mappings for Holding
                    applyFieldMappings('Holding', holdingData, fh);
                    
                    holdingsToUpsert.add(fh);
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
    }
    
    /**
     * @description Upsert transaction data for financial accounts using metadata mappings
     * @param financialAccountIds List of Financial Account IDs
     * @param comprehensiveData Complete portfolio data
     */
    private static void upsertTransactions(List<Id> financialAccountIds, SRV_InvestmentPortfolioAPI.ComprehensivePortfolioData comprehensiveData) {
        List<FinServ__FinancialAccountTransaction__c> transactionsToUpsert = new List<FinServ__FinancialAccountTransaction__c>();
        
        // Get mapping of external IDs to Financial Account IDs
        Map<String, Id> externalIdToFAId = getExternalIdToFinancialAccountMapping(financialAccountIds);
        
        // Process transactions by portfolio
        for (String externalPortfolioId : comprehensiveData.transactionsByPortfolio.keySet()) {
            Id financialAccountId = externalIdToFAId.get(externalPortfolioId);
            if (financialAccountId != null) {
                List<Map<String, Object>> transactions = comprehensiveData.transactionsByPortfolio.get(externalPortfolioId);
                
                for (Map<String, Object> txnData : transactions) {
                    FinServ__FinancialAccountTransaction__c fat = new FinServ__FinancialAccountTransaction__c();
                    fat.FinServ__FinancialAccount__c = financialAccountId;
                    
                    // Apply metadata mappings for Transaction
                    applyFieldMappings('Transaction', txnData, fat);
                    
                    transactionsToUpsert.add(fat);
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
            WITH SECURITY_ENFORCED
        ];
        
        for (FinServ__FinancialAccount__c fa : financialAccounts) {
            if (fa.ExternalPortfolioId__c != null) {
                externalIdToFAId.put(fa.ExternalPortfolioId__c, fa.Id);
            }
        }
        
        return externalIdToFAId;
    }
    
    /**
     * @description Apply field mappings from custom metadata to Salesforce record
     * @param objectType Portfolio, Holding, or Transaction
     * @param apiData API response data
     * @param record Salesforce record to populate
     */
    private static void applyFieldMappings(String objectType, Map<String, Object> apiData, SObject record) {
        // Get active field mappings for this object type
        for (Wealth360_Field_Mapping__mdt mapping : [
            SELECT API_Field_Name__c, Salesforce_Field_Name__c, Data_Type__c
            FROM Wealth360_Field_Mapping__mdt 
            WHERE Object_Type__c = :objectType AND Is_Active__c = true
        ]) {
            Object apiValue = apiData.get(mapping.API_Field_Name__c);
            if (apiValue != null) {
                Object convertedValue = convertValue(apiValue, mapping.Data_Type__c);
                if (convertedValue != null) {
                    record.put(mapping.Salesforce_Field_Name__c, convertedValue);
                }
            }
        }
    }
    
    /**
     * @description Convert API value to appropriate Salesforce data type
     * @param apiValue Raw API value
     * @param dataType Target data type
     * @return Converted value
     */
    private static Object convertValue(Object apiValue, String dataType) {
        if (apiValue == null) return null;
        
        try {
            switch on dataType {
                when 'String' { return String.valueOf(apiValue); }
                when 'Decimal' { 
                    return apiValue instanceof String ? Decimal.valueOf((String)apiValue) : (Decimal)apiValue;
                }
                when 'Date' { 
                    return apiValue instanceof String ? Date.valueOf((String)apiValue) : (Date)apiValue;
                }
                when 'DateTime' { 
                    return apiValue instanceof String ? DateTime.valueOf((String)apiValue) : (DateTime)apiValue;
                }
                when 'Boolean' { 
                    return apiValue instanceof String ? Boolean.valueOf((String)apiValue) : (Boolean)apiValue;
                }
                when else { return String.valueOf(apiValue); }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Failed to convert value: ' + apiValue + ' to type: ' + dataType);
            return null;
        }
    }
    
    /**
     * @description Handle upsert results and throw exceptions for failures
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
        
        if (!errors.isEmpty()) {
            throw new AuraHandledException('Failed to sync ' + recordType + ': ' + String.join(errors, '; '));
        }
        
        return successfulIds;
    }
}