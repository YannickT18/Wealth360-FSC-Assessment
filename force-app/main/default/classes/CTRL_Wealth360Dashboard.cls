/**
 * @description Apex controller for Wealth360 Dashboard LWC
 * @author Yannick Kayombo
 * @date 22-11-2025
 */
public with sharing class CTRL_Wealth360Dashboard {
    
    /**
     * @description Get total investment value for an account
     * @param accountId Account ID
     * @return Total investment value
     */
    @AuraEnabled(cacheable=true)
    public static Decimal getTotalInvestmentValue(Id accountId) {
        try {
            AggregateResult[] results = [
                SELECT SUM(TotalAssetValue__c) totalValue
                FROM FinServ__FinancialAccount__c
                WHERE FinServ__PrimaryOwner__c = :accountId
                AND FinServ__FinancialAccountType__c = 'Investment'
                WITH SECURITY_ENFORCED
            ];
            
            Decimal totalValue = (Decimal)results[0].get('totalValue');
            return totalValue != null ? totalValue : 0;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching total investment value: ' + e.getMessage());
        }
    }
    
    /**
     * @description Get asset allocation data for pie chart
     * @param accountId Account ID
     * @return List of asset allocation data
     */
    @AuraEnabled(cacheable=true)
    public static List<DTO_Wealth360Dashboard.AssetAllocation> getAssetAllocation(Id accountId) {
        try {
            // Get all financial accounts for the account
            List<FinServ__FinancialAccount__c> financialAccounts = [
                SELECT Id, ExternalPortfolioId__c
                FROM FinServ__FinancialAccount__c
                WHERE FinServ__PrimaryOwner__c = :accountId
                AND FinServ__FinancialAccountType__c = 'Investment'
                WITH SECURITY_ENFORCED
            ];
            
            if (financialAccounts.isEmpty()) {
                return new List<DTO_Wealth360Dashboard.AssetAllocation>();
            }
            
            Set<Id> financialAccountIds = new Set<Id>();
            for (FinServ__FinancialAccount__c fa : financialAccounts) {
                financialAccountIds.add(fa.Id);
            }
            
            // Aggregate holdings by asset category
            AggregateResult[] results = [
                SELECT FinServ__AssetCategory__c category, 
                       SUM(FinServ__MarketValue__c) totalValue
                FROM FinServ__FinancialHolding__c
                WHERE FinServ__FinancialAccount__c IN :financialAccountIds
                WITH SECURITY_ENFORCED
                GROUP BY FinServ__AssetCategory__c
            ];
            
            List<DTO_Wealth360Dashboard.AssetAllocation> allocations = new List<DTO_Wealth360Dashboard.AssetAllocation>();
            Decimal grandTotal = 0;
            
            // First pass: calculate total
            for (AggregateResult ar : results) {
                Decimal value = (Decimal)ar.get('totalValue');
                if (value != null) {
                    grandTotal += value;
                }
            }
            
            // Second pass: calculate percentages
            for (AggregateResult ar : results) {
                String category = (String)ar.get('category');
                Decimal value = (Decimal)ar.get('totalValue');
                
                if (category != null && value != null && grandTotal > 0) {
                    Decimal percentage = (value / grandTotal * 100).setScale(2);
                    allocations.add(new DTO_Wealth360Dashboard.AssetAllocation(category, value, percentage));
                }
            }
            
            return allocations;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching asset allocation: ' + e.getMessage());
        }
    }
    
    /**
     * @description Get recent transactions for an account
     * @param accountId Account ID
     * @param limitCount Number of transactions to return
     * @return List of recent transactions
     */
    @AuraEnabled(cacheable=true)
    public static List<DTO_Wealth360Dashboard.TransactionData> getRecentTransactions(Id accountId, Integer limitCount) {
        try {
            Integer recordLimit = limitCount != null ? limitCount : 10;
            
            // Get financial accounts for the account
            List<FinServ__FinancialAccount__c> financialAccounts = [
                SELECT Id
                FROM FinServ__FinancialAccount__c
                WHERE FinServ__PrimaryOwner__c = :accountId
                AND FinServ__FinancialAccountType__c = 'Investment'
                WITH SECURITY_ENFORCED
            ];
            
            if (financialAccounts.isEmpty()) {
                return new List<DTO_Wealth360Dashboard.TransactionData>();
            }
            
            Set<Id> financialAccountIds = new Set<Id>();
            for (FinServ__FinancialAccount__c fa : financialAccounts) {
                financialAccountIds.add(fa.Id);
            }
            
            // Query recent transactions
            List<FinServ__FinancialAccountTransaction__c> transactions = [
                SELECT Id, Name,
                       FinServ__TransactionType__c,
                       FinServ__Amount__c,
                       FinServ__TransactionDate__c,
                       FinServ__TransactionStatus__c,
                       FinServ__Description__c,
                       FinServ__FinancialAccount__r.Name
                FROM FinServ__FinancialAccountTransaction__c
                WHERE FinServ__FinancialAccount__c IN :financialAccountIds
                WITH SECURITY_ENFORCED
                ORDER BY FinServ__TransactionDate__c DESC
                LIMIT :recordLimit
            ];
            
            // Strip inaccessible fields for security
            SObjectAccessDecision decision = Security.stripInaccessible(
                AccessType.READABLE, transactions
            );
            
            List<DTO_Wealth360Dashboard.TransactionData> transactionDataList = new List<DTO_Wealth360Dashboard.TransactionData>();
            for (FinServ__FinancialAccountTransaction__c txn : 
                 (List<FinServ__FinancialAccountTransaction__c>)decision.getRecords()) {
                transactionDataList.add(new DTO_Wealth360Dashboard.TransactionData(txn));
            }
            
            return transactionDataList;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching recent transactions: ' + e.getMessage());
        }
    }
    
    /**
     * @description Trigger portfolio sync for an account (simplified with proper separation of concerns)
     * @param accountId Account ID
     * @return Success message
     */
    @AuraEnabled
    public static String syncPortfolioData(Id accountId) {
        try {
            // Single method call handles API + business logic
            SRV_InvestmentPortfolio.SyncResult result = SRV_InvestmentPortfolio.fetchAndSyncPortfolioData(accountId);
            
            if (result.success) {
                return 'SUCCESS: ' + result.portfoliosSynced + ' portfolios, ' + 
                       result.holdingsSynced + ' holdings, ' + result.transactionsSynced + ' transactions synced';
            } else {
                throw new AuraHandledException(result.message);
            }
            
        } catch (Exception e) {
            throw new AuraHandledException('Error syncing portfolio data: ' + e.getMessage());
        }
    }
    
    /**
     * @description Get portfolio summary statistics
     * @param accountId Account ID
     * @return Portfolio summary data
     */
    @AuraEnabled(cacheable=true)
    public static DTO_Wealth360Dashboard.PortfolioSummary getPortfolioSummary(Id accountId) {
        try {
            DTO_Wealth360Dashboard.PortfolioSummary summary = new DTO_Wealth360Dashboard.PortfolioSummary();
            
            // Get portfolio count and total value
            AggregateResult[] portfolioResults = [
                SELECT COUNT(Id) portfolioCount,
                       SUM(TotalAssetValue__c) totalValue
                FROM FinServ__FinancialAccount__c
                WHERE FinServ__PrimaryOwner__c = :accountId
                AND FinServ__FinancialAccountType__c = 'Investment'
                WITH SECURITY_ENFORCED
            ];
            
            summary.portfolioCount = (Integer)portfolioResults[0].get('portfolioCount');
            summary.totalValue = (Decimal)portfolioResults[0].get('totalValue');
            summary.totalValue = summary.totalValue != null ? summary.totalValue : 0;
            
            // Get holdings count
            List<FinServ__FinancialAccount__c> financialAccounts = [
                SELECT Id
                FROM FinServ__FinancialAccount__c
                WHERE FinServ__PrimaryOwner__c = :accountId
                AND FinServ__FinancialAccountType__c = 'Investment'
                WITH SECURITY_ENFORCED
            ];
            
            Set<Id> faIds = new Set<Id>();
            for (FinServ__FinancialAccount__c fa : financialAccounts) {
                faIds.add(fa.Id);
            }
            
            AggregateResult[] holdingResults = [
                SELECT COUNT(Id) holdingCount
                FROM FinServ__FinancialHolding__c
                WHERE FinServ__FinancialAccount__c IN :faIds
                WITH SECURITY_ENFORCED
            ];
            
            summary.holdingsCount = (Integer)holdingResults[0].get('holdingCount');
            
            return summary;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching portfolio summary: ' + e.getMessage());
        }
    }
}
