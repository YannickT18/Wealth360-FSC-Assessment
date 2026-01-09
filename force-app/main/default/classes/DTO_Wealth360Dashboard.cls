/**
 * @description Data Transfer Object (DTO) classes for Wealth360 Dashboard
 * @author Wealth360 Team
 * @date 2026
 * 
 * Contains all data transfer objects used by CTRL_Wealth360Dashboard
 */
public with sharing class DTO_Wealth360Dashboard {
    
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
     * @description Transaction data for recent transactions display
     */
    public class TransactionData {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String type { get; set; }
        @AuraEnabled public Decimal amount { get; set; }
        @AuraEnabled public Date transactionDate { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public String accountName { get; set; }
        
        public TransactionData() {}
        
        public TransactionData(FinServ__FinancialAccountTransaction__c txn) {
            this.id = txn.Id;
            this.name = txn.Name;
            this.type = txn.FinServ__TransactionType__c;
            this.amount = txn.FinServ__Amount__c;
            this.transactionDate = txn.FinServ__TransactionDate__c != null ? 
                txn.FinServ__TransactionDate__c.date() : null;
            this.status = txn.FinServ__TransactionStatus__c;
            this.description = txn.FinServ__Description__c;
            this.accountName = txn.FinServ__FinancialAccount__r?.Name;
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
     * @description Portfolio performance data
     */
    public class PortfolioPerformance {
        @AuraEnabled public String portfolioName { get; set; }
        @AuraEnabled public Decimal currentValue { get; set; }
        @AuraEnabled public Decimal previousValue { get; set; }
        @AuraEnabled public Decimal changeAmount { get; set; }
        @AuraEnabled public Decimal changePercentage { get; set; }
        @AuraEnabled public String trend { get; set; } // 'up', 'down', 'neutral'
        
        public PortfolioPerformance() {}
        
        public PortfolioPerformance(String name, Decimal current, Decimal previous) {
            this.portfolioName = name;
            this.currentValue = current;
            this.previousValue = previous;
            
            if (current != null && previous != null && previous != 0) {
                this.changeAmount = current - previous;
                this.changePercentage = ((current - previous) / previous * 100).setScale(2);
                this.trend = changeAmount > 0 ? 'up' : changeAmount < 0 ? 'down' : 'neutral';
            } else {
                this.changeAmount = 0;
                this.changePercentage = 0;
                this.trend = 'neutral';
            }
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
        
        public static ApiResponse success(String message, Object data) {
            ApiResponse response = new ApiResponse();
            response.success = true;
            response.message = message;
            response.data = data;
            return response;
        }
        
        public static ApiResponse error(String message, String errorCode) {
            ApiResponse response = new ApiResponse();
            response.success = false;
            response.message = message;
            response.errorCode = errorCode;
            return response;
        }
    }
}