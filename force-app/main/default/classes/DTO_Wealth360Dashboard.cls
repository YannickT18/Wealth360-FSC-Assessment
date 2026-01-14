/**
 * @description DTO for Wealth360 Dashboard API response matching actual payload structure
 * @author Yannick Kayombo 
 * @date November 2025
 */
public with sharing class DTO_Wealth360Dashboard {
    
    @AuraEnabled public Boolean success { get; set; }
    @AuraEnabled public List<Portfolio> portfolios { get; set; }
    @AuraEnabled public Map<String, List<Holding>> holdingsByPortfolio { get; set; }
    @AuraEnabled public Map<String, List<TransactionData>> transactionsByPortfolio { get; set; }

    /**
     * @description Portfolio information matching the API response
     */
    public class Portfolio {
        @AuraEnabled public String portfolioId { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public Decimal total_value { get; set; }
        @AuraEnabled public String currency { get; set; }
        @AuraEnabled public String type { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public String lastUpdated { get; set; }
    }

    /**
     * @description Holding information for each portfolio
     */
    public class Holding {
        @AuraEnabled public String holdingId { get; set; }
        @AuraEnabled public String portfolio_id { get; set; }
        @AuraEnabled public String asset_category { get; set; }
        @AuraEnabled public String asset_name { get; set; }
        @AuraEnabled public Decimal market_value { get; set; }
        @AuraEnabled public Integer quantity { get; set; }
        @AuraEnabled public Decimal price_per_unit { get; set; }
        @AuraEnabled public String last_updated { get; set; }
    }
    
    /**
     * @description Transaction data for each portfolio
     */
    public class TransactionData {
        @AuraEnabled public String transactionId { get; set; }
        @AuraEnabled public String portfolio_id { get; set; }
        @AuraEnabled public String transaction_type { get; set; }
        @AuraEnabled public Decimal amount { get; set; }
        @AuraEnabled public String transaction_date { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public String description { get; set; }
        
        public TransactionData() {}
        
        // Constructor for backward compatibility with Financial Services objects
        public TransactionData(FinServ__FinancialAccountTransaction__c txn) {
            this.transactionId = txn.Id;
            this.transaction_type = txn.FinServ__TransactionType__c;
            this.amount = txn.FinServ__Amount__c;
            this.transaction_date = txn.FinServ__TransactionDate__c != null ? 
                txn.FinServ__TransactionDate__c.format() : null;
            this.status = txn.FinServ__TransactionStatus__c;
            this.description = txn.FinServ__Description__c;
            this.portfolio_id = txn.FinServ__FinancialAccount__c;
        }
    }

    /**
     * @description Asset allocation data for pie charts and portfolio breakdowns
     */
    public class AssetAllocation {
        @AuraEnabled public String category { get; set; }
        @AuraEnabled public Decimal value { get; set; }
        @AuraEnabled public Decimal percentage { get; set; }
        
        public AssetAllocation() {}
        
        public AssetAllocation(String category, Decimal value, Decimal percentage) {
            this.category = category;
            this.value = value;
            this.percentage = percentage;
        }
    }

    /**
     * @description Portfolio summary statistics for dashboard overview
     */
    public class PortfolioSummary {
        @AuraEnabled public Integer portfolioCount { get; set; }
        @AuraEnabled public Integer holdingsCount { get; set; }
        @AuraEnabled public Decimal totalValue { get; set; }
        @AuraEnabled public Date lastSyncDate { get; set; }
        @AuraEnabled public String status { get; set; }
        
        public PortfolioSummary() {
            this.portfolioCount = 0;
            this.holdingsCount = 0;
            this.totalValue = 0;
            this.status = 'Ready';
        }
    }
    
    /**
     * @description Generic response wrapper for API-style responses
     */
    public class ApiResponse {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public Object data { get; set; }
        @AuraEnabled public String errorCode { get; set; }
        
        public ApiResponse() {}
        
        public ApiResponse(Boolean success, String message, Object data, String errorCode) {
            this.success = success;
            this.message = message;
            this.data = data;
            this.errorCode = errorCode;
        }
        
        public ApiResponse withSuccess(String message, Object data) {
            this.success = true;
            this.message = message;
            this.data = data;
            return this;
        }
        
        public ApiResponse withError(String message, String errorCode) {
            this.success = false;
            this.message = message;
            this.errorCode = errorCode;
            return this;
        }
    }
}