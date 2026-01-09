# Method-by-Method Breakdown - Wealth360 FSC Assessment
**Author:** Yannick Kayombo | **Date:** January 9, 2026

---

## 🎛️ **CTRL_Wealth360Dashboard - Controller Methods**

### **Public @AuraEnabled Methods**

#### **`getTotalInvestmentValue(Id accountId)` - @AuraEnabled(cacheable=true)**
```apex
// What it does: Calculates total portfolio value for an account
// Input: Account ID
// Output: Decimal (total investment value)
// Security: WITH SECURITY_ENFORCED
// Caching: Cacheable for performance
```
**Business Logic:**
- Runs aggregate SOQL on FinServ__FinancialAccount__c
- Sums TotalAssetValue__c for Investment accounts
- Returns 0 if no investments found
- Used by dashboard total value widget

#### **`getAssetAllocation(Id accountId)` - @AuraEnabled(cacheable=true)**
```apex
// What it does: Gets asset breakdown for pie chart
// Input: Account ID  
// Output: List<DTO_Wealth360Dashboard.AssetAllocation>
// Security: WITH SECURITY_ENFORCED
// Caching: Cacheable for performance
```
**Business Logic:**
- Queries holdings grouped by asset category
- Calculates percentage of total portfolio per category
- Formats data for chart visualization
- Used by asset allocation pie chart

#### **`getRecentTransactions(Id accountId, Integer limitCount)` - @AuraEnabled(cacheable=true)**
```apex
// What it does: Gets transaction history for display
// Input: Account ID, number of transactions
// Output: List<DTO_Wealth360Dashboard.TransactionData>
// Security: WITH SECURITY_ENFORCED
// Caching: Cacheable for performance
```
**Business Logic:**
- Queries FinServ__FinancialAccountTransaction__c
- Orders by transaction date DESC
- Applies user-specified limit
- Used by transaction history table

#### **`syncPortfolioData(Id accountId)` - @AuraEnabled**
```apex
// What it does: Manually trigger portfolio sync
// Input: Account ID
// Output: String ('SUCCESS' or error message)
// Security: with sharing
// Caching: Not cacheable (write operation)
```
**Business Logic:**
- Calls SRV_InvestmentPortfolioAPI.getAllPortfolioDataForSync()
- Uses SRV_PortfolioUpdate.syncComprehensivePortfolioData()
- Returns user-friendly success/error message
- Used by manual sync button

#### **`getPortfolioSummary(Id accountId)` - @AuraEnabled(cacheable=true)**
```apex
// What it does: Gets portfolio performance summary
// Input: Account ID
// Output: DTO_Wealth360Dashboard.PortfolioSummary
// Security: WITH SECURITY_ENFORCED  
// Caching: Cacheable for performance
```
**Business Logic:**
- Aggregates data from multiple FSC objects
- Calculates performance metrics
- Formats for dashboard summary widgets
- Used by performance summary cards

---

## 🔌 **SRV_InvestmentPortfolioAPI - API Service Methods**

### **Public Static Methods**

#### **`getComprehensivePortfolioData(Id accountId, Boolean includeHoldings, Boolean includeTransactions, Integer transactionDays)`**
```apex
// What it does: Main API integration method with flexible parameters
// Input: Account ID, include flags, transaction history days
// Output: APIResponse with comprehensive data
// Pattern: Single API call optimization
```
**Business Logic:**
- Builds endpoint URL with query parameters
- Calls comprehensive API endpoint once
- Returns structured APIResponse object
- Optimizes API usage with single call

#### **`getAllPortfolioDataForSync(Id accountId)`**
```apex
// What it does: Convenience method for Salesforce sync
// Input: Account ID
// Output: ComprehensivePortfolioData object
// Pattern: Facade pattern for complex API
```
**Business Logic:**
- Calls getComprehensivePortfolioData() with sync-optimized parameters
- Parses response into structured Apex objects
- Returns empty structure if API fails
- Used by sync operations

### **Private Helper Methods**

#### **`makeCalloutWithRetry(String endpoint, String method, String body)`**
```apex
// What it does: HTTP callout with retry logic
// Input: Endpoint, HTTP method, request body
// Output: APIResponse
// Pattern: Retry with exponential backoff
```
**Business Logic:**
- Implements retry logic for API reliability
- Exponential backoff for rate limiting
- Comprehensive error handling
- Returns structured response

#### **`parseComprehensiveData(Map<String, Object> responseData)`**
```apex
// What it does: Parse API JSON into Apex objects
// Input: Raw API response data
// Output: ComprehensivePortfolioData
// Pattern: Data transformation layer
```
**Business Logic:**
- Transforms JSON to type-safe Apex objects
- Groups holdings and transactions by portfolio
- Handles missing or malformed data
- Provides clean data contracts

---

## 🏭 **SRV_PortfolioUpdate - Business Logic Methods**

### **Public Static Methods**

#### **`syncComprehensivePortfolioData(Id accountId, ComprehensivePortfolioData data)`**
```apex
// What it does: Main orchestration method for data sync
// Input: Account ID, comprehensive API data
// Output: Void
// Pattern: Service orchestration
```
**Business Logic:**
- Orchestrates upsert operations in correct order
- Maintains referential integrity (parent-child)
- Uses metadata-driven field mapping
- Handles bulk operations efficiently

### **Private Helper Methods**

#### **`upsertPortfolios(Id accountId, List<Map<String, Object>> portfolios)`**
```apex
// What it does: Create/update Financial Account records
// Input: Account ID, portfolio data list
// Output: List<Id> (Financial Account IDs)
// Pattern: External ID for idempotent operations
```
**Business Logic:**
- Maps API data to FinServ__FinancialAccount__c
- Uses External ID to prevent duplicates
- Returns created record IDs for child objects
- Maintains data integrity

#### **`upsertHoldings(List<Id> financialAccountIds, ComprehensivePortfolioData data)`**
```apex
// What it does: Create/update Financial Holding records
// Input: Parent record IDs, comprehensive data
// Output: Void
// Pattern: Bulk DML operations
```
**Business Logic:**
- Links holdings to correct financial accounts
- Maps asset categories and market values
- Calculates portfolio percentages
- Uses external ID for idempotency

#### **`upsertTransactions(List<Id> financialAccountIds, ComprehensivePortfolioData data)`**
```apex
// What it does: Create/update transaction records
// Input: Parent record IDs, comprehensive data
// Output: Void
// Pattern: Date parsing and type mapping
```
**Business Logic:**
- Maps transaction data from API
- Handles date string parsing
- Maps transaction types (BUY, SELL, DIVIDEND)
- Links to appropriate financial accounts

---

## 🔄 **Queueable_PortfolioSync - Async Processing Methods**

### **Public Methods**

#### **`Constructor: Queueable_PortfolioSync(List<Id> accountIds)`**
```apex
// What it does: Initialize async job with account list
// Input: List of Account IDs to process
// Output: Queueable job instance
// Pattern: Batch initialization
```
**Business Logic:**
- Stores account IDs for processing
- Sets batch size (50 per job)
- Initializes batch counter
- Prepares for bulk processing

#### **`execute(QueueableContext context)` - Framework Method**
```apex
// What it does: Main execution called by Salesforce
// Input: QueueableContext
// Output: Void
// Pattern: Template method pattern
```
**Business Logic:**
- Try-catch for job-level error handling
- Calls syncPortfolios() for actual work
- Logs errors without failing entire job
- Framework callback implementation

### **Private Worker Methods**

#### **`syncPortfolios()`**
```apex
// What it does: Process current batch of accounts
// Input: Uses instance variables
// Output: Void  
// Pattern: Batch processing with chaining
```
**Business Logic:**
- Calculates current batch boundaries
- Makes API calls for each account
- Collects data for bulk DML
- Chains next job if more accounts remain

#### **`upsertFinancialData(accounts, holdings, transactions)`**
```apex
// What it does: Bulk DML operations for all record types
// Input: Lists of records to upsert
// Output: Void
// Pattern: Bulk operations with partial success
```
**Business Logic:**
- Upserts Financial Accounts first (parent)
- Then Holdings and Transactions (children)
- Uses allOrNone=false for partial success
- Logs individual record failures

---

## 📊 **DTO_Wealth360Dashboard - Data Transfer Objects**

### **Data Classes (No Methods)**

#### **`AssetAllocation`**
```apex
// Purpose: Structure asset category data for charts
// Properties: category, value, percentage
// Usage: Pie chart data binding
```

#### **`TransactionData`**
```apex
// Purpose: Structure transaction data for tables
// Properties: transactionId, type, amount, date, description
// Usage: Transaction history display
```

#### **`PortfolioSummary`**
```apex
// Purpose: Aggregate performance metrics
// Properties: totalValue, gainLoss, percentage, lastUpdated
// Usage: Dashboard summary widgets
```

#### **`PortfolioPerformance`**
```apex
// Purpose: Track performance over time
// Properties: portfolioName, currentValue, previousValue, changes
// Usage: Performance tracking
```

---

## 🧪 **TEST_DataFactory - Test Support Methods**

### **Public Test Methods**

#### **`createAccount(String lastName, Boolean doInsert)`**
```apex
// What it does: Create test Account (Person Account)
// Input: Last name, whether to insert
// Output: Account record
// Pattern: Test data factory
```

#### **`createAccounts(Integer count, Boolean doInsert)`**
```apex
// What it does: Create multiple test accounts
// Input: Count, whether to insert
// Output: List<Account>
// Pattern: Bulk test data creation
```

#### **`createFinancialAccount(Id accountId, String portfolioType, Boolean doInsert)`**
```apex
// What it does: Create FSC Financial Account
// Input: Parent account ID, type, insert flag
// Output: FinServ__FinancialAccount__c
// Pattern: FSC object relationships
```

### **Inner Test Class**

#### **`Mock_InvestmentPortfolioAPI` (implements HttpCalloutMock)**
```apex
// What it does: HTTP mock for API tests
// Methods: respond(), createMockResponse()
// Pattern: Test double for external dependencies
```

**Mock Features:**
- Success and error response simulation
- Realistic JSON response structure
- Configurable status codes
- Integrated in test data factory

---

**🎯 Study Tip:** Focus on understanding the flow between these methods - how data moves from API → Service → Controller → UI, and how async processing handles bulk operations!