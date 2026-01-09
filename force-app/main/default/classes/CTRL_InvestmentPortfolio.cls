/**
 * @description Investment Portfolio Dashboard Controller - handles UI interactions for portfolioDashboard LWC
 * @author Wealth360 Dev Team
 * @date 2024
 */
public with sharing class CTRL_InvestmentPortfolio {
    
    /**
     * @description Gets financial accounts for an account (alias for getPortfolios)
     * @param accountId Account ID
     * @return ResponseWrapper with financial account data or error message
     */
    @AuraEnabled(cacheable=true)
    public static WRP_InvestmentPortfolio.ResponseWrapper getFinancialAccounts(Id accountId) {
        return getPortfolios(accountId);
    }
    
    /**
     * @description Gets portfolios (financial accounts) for an account
     * @param accountId Account ID
     * @return ResponseWrapper with portfolio data or error message
     */
    @AuraEnabled(cacheable=true)
    public static WRP_InvestmentPortfolio.ResponseWrapper getPortfolios(Id accountId) {
        try {
            List<FinServ__FinancialAccount__c> portfolios = [
                SELECT Id, Name, FinServ__FinancialAccountNumber__c, 
                       FinServ__FinancialAccountType__c, FinServ__Balance__c, 
                       FinServ__Status__c, TotalAssetValue__c, LastSyncDate__c
                FROM FinServ__FinancialAccount__c
                WHERE FinServ__PrimaryOwner__c = :accountId 
                WITH USER_MODE
                ORDER BY FinServ__Balance__c DESC NULLS LAST
            ];
            return WRP_InvestmentPortfolio.success('Success', portfolios);
        } catch (Exception e) {
            return WRP_InvestmentPortfolio.error('Error loading portfolios: ' + e.getMessage());
        }
    }
    
    /**
     * @description Gets holdings for a financial account
     * @param financialAccountId Financial Account ID
     * @return ResponseWrapper with holdings data or error message
     */
    @AuraEnabled(cacheable=true)
    public static WRP_InvestmentPortfolio.ResponseWrapper getHoldings(Id financialAccountId) {
        try {
            List<FinServ__FinancialHolding__c> holdings = [
                SELECT Id, Name, FinServ__AssetCategory__c,
                       FinServ__Shares__c, FinServ__Price__c, 
                       FinServ__MarketValue__c, PercentOfPortfolio__c
                FROM FinServ__FinancialHolding__c
                WHERE FinServ__FinancialAccount__c = :financialAccountId
                WITH USER_MODE
                ORDER BY FinServ__MarketValue__c DESC NULLS LAST
            ];
            return WRP_InvestmentPortfolio.success('Success', holdings);
        } catch (Exception e) {
            return WRP_InvestmentPortfolio.error('Error loading holdings: ' + e.getMessage());
        }
    }
    
    /**
     * @description Gets recent transactions for an account
     * @param accountId Account ID
     * @param limitCount Number of transactions to retrieve
     * @return ResponseWrapper with transaction data or error message
     */
    @AuraEnabled(cacheable=true)
    public static WRP_InvestmentPortfolio.ResponseWrapper getRecentTransactions(Id accountId, Integer limitCount) {
        try {
            limitCount = limitCount != null && limitCount > 0 ? limitCount : 10;
            
            List<FinServ__FinancialAccountTransaction__c> transactions = [
                SELECT Id, Name, FinServ__FinancialAccount__r.Name, 
                       FinServ__TransactionDate__c, FinServ__TransactionType__c,
                       FinServ__Amount__c, FinServ__TransactionStatus__c
                FROM FinServ__FinancialAccountTransaction__c
                WHERE FinServ__FinancialAccount__r.FinServ__PrimaryOwner__c = :accountId
                WITH USER_MODE
                ORDER BY FinServ__TransactionDate__c DESC
                LIMIT :limitCount
            ];
            return WRP_InvestmentPortfolio.success('Success', transactions);
        } catch (Exception e) {
            return WRP_InvestmentPortfolio.error('Error loading transactions: ' + e.getMessage());
        }
    }
    
    /**
     * @description Gets asset allocation breakdown for an account
     * @param accountId Account ID
     * @return ResponseWrapper with allocation map or error message
     */
    @AuraEnabled(cacheable=true)
    public static WRP_InvestmentPortfolio.ResponseWrapper getAssetAllocation(Id accountId) {
        try {
            Map<String, Decimal> allocation = new Map<String, Decimal>();
            
            List<AggregateResult> results = [
                SELECT FinServ__AssetCategory__c category, 
                       SUM(FinServ__MarketValue__c) totalValue
                FROM FinServ__FinancialHolding__c
                WHERE FinServ__FinancialAccount__r.FinServ__PrimaryOwner__c = :accountId
                WITH USER_MODE
                GROUP BY FinServ__AssetCategory__c
            ];
            
            for (AggregateResult ar : results) {
                String category = (String)ar.get('category');
                Decimal value = (Decimal)ar.get('totalValue');
                if (category != null && value != null) {
                    allocation.put(category, value);
                }
            }
            
            return WRP_InvestmentPortfolio.success('Success', allocation);
        } catch (Exception e) {
            return WRP_InvestmentPortfolio.error('Error calculating allocation: ' + e.getMessage());
        }
    }
    
    /**
     * @description Initiates portfolio sync for an account
     * @param accountId Account ID
     * @return ResponseWrapper with success message or error
     */
    @AuraEnabled
    public static WRP_InvestmentPortfolio.ResponseWrapper syncPortfolio(Id accountId) {
        try {
            List<Account> accounts = [
                SELECT Id, ExternalClientId__c 
                FROM Account 
                WHERE Id = :accountId 
                WITH USER_MODE 
                LIMIT 1
            ];
            
            if (accounts.isEmpty()) {
                return WRP_InvestmentPortfolio.error('Account not found');
            }
            
            if (String.isBlank(accounts[0].ExternalClientId__c)) {
                return WRP_InvestmentPortfolio.error('Account missing External Client ID');
            }
            
            // Queue the sync job
            System.enqueueJob(new Queueable_InvestmentPortfolioSync(new List<Id>{accountId}));
            
            return WRP_InvestmentPortfolio.success('Portfolio sync started successfully', null);
            
        } catch (Exception e) {
            return WRP_InvestmentPortfolio.error('Error starting sync: ' + e.getMessage());
        }
    }
}
