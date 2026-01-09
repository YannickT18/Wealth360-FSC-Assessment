# Wealth360 FSC Assessment - Interview Study Guide
**Author:** Yannick Kayombo  
**Date:** January 9, 2026

---

## 🏗️ **Architecture Overview**

### **Component Descriptions**

**🎛️ CTRL_Wealth360Dashboard**
- **Purpose:** Lightning Web Component controller for dashboard functionality
- **Role:** Handles all data retrieval for the UI, delegates business logic to services
- **Key Features:** Cacheable methods, security enforcement, error handling

**🔌 SRV_InvestmentPortfolioAPI** 
- **Purpose:** API integration service for external portfolio data
- **Role:** Handles HTTP callouts to external investment API
- **Key Features:** Named credentials, comprehensive data retrieval, error handling

**🏭 SRV_PortfolioUpdate**
- **Purpose:** Business logic service for portfolio data processing
- **Role:** Handles data transformation and database operations
- **Key Features:** Metadata-driven field mapping, bulk operations

**📊 DTO_Wealth360Dashboard**
- **Purpose:** Data Transfer Objects for clean UI data contracts
- **Role:** Structures data between controller and UI components
- **Key Features:** Type safety, clean data structure

**🔄 Queueable_PortfolioSync**
- **Purpose:** Asynchronous bulk data synchronization
- **Role:** Processes large datasets without hitting governor limits
- **Key Features:** Job chaining, bulk processing, comprehensive sync

**🧪 TEST_DataFactory**
- **Purpose:** Test data creation and HTTP mocking
- **Role:** Provides reusable test data and mock responses
- **Key Features:** FSC relationship handling, integrated mocking

---

## 📋 **Detailed Method Analysis**

### 🎛️ **CTRL_Wealth360Dashboard Methods**

#### **getTotalInvestmentValue(Id accountId)**
- **Purpose:** Calculate total investment portfolio value for an account
- **How it works:** 
  - Runs aggregate SOQL query on FinServ__FinancialAccount__c
  - Sums TotalAssetValue__c for Investment type accounts
  - Uses WITH SECURITY_ENFORCED for field-level security
- **Returns:** Decimal - total value or 0 if null
- **UI Usage:** Wire service for real-time dashboard display

#### **getAssetAllocation(Id accountId)**
- **Purpose:** Get asset category breakdown for pie charts
- **How it works:**
  - Queries financial accounts for the user
  - Groups holdings by asset category
  - Calculates percentages and values per category
- **Returns:** List<DTO_Wealth360Dashboard.AssetAllocation>
- **UI Usage:** Pie chart visualization

#### **getRecentTransactions(Id accountId, Integer limitCount)**
- **Purpose:** Retrieve recent transaction history for display
- **How it works:**
  - Queries FinServ__FinancialAccountTransaction__c
  - Orders by transaction date (most recent first)
  - Applies user-specified limit
- **Returns:** List<DTO_Wealth360Dashboard.TransactionData>
- **UI Usage:** Transaction history table

#### **syncPortfolioData(Id accountId)**
- **Purpose:** Trigger manual portfolio data synchronization
- **How it works:**
  - Calls SRV_InvestmentPortfolioAPI for comprehensive data
  - Uses SRV_PortfolioUpdate for data processing
  - Handles errors with user-friendly messages
- **Returns:** String - 'SUCCESS' or error message
- **UI Usage:** Manual sync button functionality

#### **getPortfolioSummary(Id accountId)**
- **Purpose:** Aggregate portfolio performance metrics
- **How it works:**
  - Combines data from multiple FSC objects
  - Calculates performance indicators
  - Structures data for dashboard widgets
- **Returns:** DTO_Wealth360Dashboard.PortfolioSummary
- **UI Usage:** Dashboard summary cards

---

### 🔌 **SRV_InvestmentPortfolioAPI Methods**

#### **getAllPortfolioDataForSync(Id accountId)**
- **Purpose:** Single comprehensive API call for all portfolio data
- **How it works:**
  - Builds HTTP request with Named Credential
  - Calls external API's comprehensive endpoint
  - Deserializes response to structured data
- **Returns:** ComprehensivePortfolioData object
- **Performance:** Single API call vs multiple calls (optimization)

#### **buildHttpRequest(Id accountId)** (Private)
- **Purpose:** Construct HTTP request with proper headers
- **How it works:**
  - Sets endpoint URL with Named Credential
  - Adds required headers (Content-Type, timeout)
  - Includes account ID as query parameter
- **Returns:** HttpRequest object
- **Security:** Uses Named Credential for authentication

#### **executeRequest(HttpRequest request)** (Private)
- **Purpose:** Execute HTTP callout with error handling
- **How it works:**
  - Sends HTTP request
  - Checks response status code
  - Throws meaningful exceptions on errors
- **Returns:** HttpResponse object
- **Error Handling:** Custom CalloutException for non-200 responses

#### **parseComprehensiveResponse(HttpResponse response)** (Private)
- **Purpose:** Convert JSON response to Apex objects
- **How it works:**
  - Deserializes JSON using System.JSON.deserialize()
  - Maps to ComprehensivePortfolioData structure
  - Type-safe data handling
- **Returns:** ComprehensivePortfolioData object
- **Data Safety:** Structured wrapper classes prevent runtime errors

---

### 🏭 **SRV_PortfolioUpdate Methods**

#### **syncComprehensivePortfolioData(Id accountId, ComprehensivePortfolioData data)**
- **Purpose:** Process and save comprehensive API data to Salesforce
- **How it works:**
  - Orchestrates upsert operations for portfolios, holdings, transactions
  - Maintains data relationships and integrity
  - Uses metadata-driven field mapping
- **Returns:** Void
- **Pattern:** Service orchestration with multiple data types

#### **upsertPortfolios(Id accountId, List<PortfolioData> portfolios)**
- **Purpose:** Create/update Financial Account records from portfolio data
- **How it works:**
  - Maps API data to FinServ__FinancialAccount__c fields
  - Uses external ID for idempotent operations
  - Returns list of created/updated record IDs
- **Returns:** List<Id> - Financial Account IDs
- **Data Integrity:** External ID prevents duplicates

#### **upsertHoldings(List<Id> financialAccountIds, ComprehensivePortfolioData data)**
- **Purpose:** Create/update Financial Holding records
- **How it works:**
  - Links holdings to correct financial accounts
  - Maps asset categories and values
  - Calculates portfolio percentages
- **Returns:** Void
- **Relationships:** Maintains parent-child relationships

#### **upsertTransactions(List<Id> financialAccountIds, ComprehensivePortfolioData data)**
- **Purpose:** Create/update Financial Account Transaction records
- **How it works:**
  - Maps transaction data from API
  - Handles date parsing and type mapping
  - Links to appropriate financial accounts
- **Returns:** Void
- **Data Types:** Handles various transaction types (BUY, SELL, DIVIDEND)

---

### 🔄 **Queueable_PortfolioSync Methods**

#### **Constructor: Queueable_PortfolioSync(List<Id> accountIds)**
- **Purpose:** Initialize queueable job with account list
- **How it works:**
  - Stores account IDs for processing
  - Sets batch size (50 accounts per job)
  - Initializes batch counter
- **Parameters:** List of Account IDs to sync
- **Pattern:** Bulkification for large datasets

#### **execute(QueueableContext context)**
- **Purpose:** Main execution method called by Salesforce framework
- **How it works:**
  - Try-catch for comprehensive error handling
  - Calls syncPortfolios() for data processing
  - Logs errors for debugging
- **Framework:** Implements Queueable interface
- **Error Handling:** Prevents job failure from stopping other jobs

#### **syncPortfolios()** (Private)
- **Purpose:** Process current batch of accounts
- **How it works:**
  - Calculates current batch range
  - Makes API calls for each account
  - Collects data for bulk DML operations
  - Chains next job if more accounts remain
- **Scalability:** Unlimited accounts via job chaining
- **Performance:** Batch processing prevents governor limits

#### **upsertFinancialData(...records)** (Private)
- **Purpose:** Bulk upsert all record types
- **How it works:**
  - Processes Financial Accounts first (parent records)
  - Then Holdings and Transactions (child records)
  - Uses allOrNone=false for partial success
- **Data Integrity:** Maintains referential integrity
- **Error Handling:** Continues processing even if some records fail

---

### 📊 **DTO_Wealth360Dashboard Classes**

#### **AssetAllocation**
- **Purpose:** Structure asset category data for pie charts
- **Properties:**
  - `category` (String) - Asset type (Stocks, Bonds, etc.)
  - `value` (Decimal) - Dollar value in category
  - `percentage` (Decimal) - Percentage of total portfolio
- **Usage:** Chart data binding in LWC

#### **TransactionData** 
- **Purpose:** Structure transaction information for UI tables
- **Properties:**
  - `transactionId` (String) - Unique identifier
  - `type` (String) - BUY, SELL, DIVIDEND, etc.
  - `amount` (Decimal) - Transaction amount
  - `transactionDate` (Date) - When transaction occurred
  - `description` (String) - Transaction details
- **Usage:** Transaction history display

#### **PortfolioSummary**
- **Purpose:** Aggregate portfolio performance data
- **Properties:**
  - `totalValue` (Decimal) - Current portfolio value
  - `totalGainLoss` (Decimal) - Profit/loss amount
  - `gainLossPercentage` (Decimal) - Performance percentage
  - `lastUpdated` (DateTime) - Last sync timestamp
- **Usage:** Dashboard summary widgets

#### **PortfolioPerformance**
- **Purpose:** Track portfolio performance over time
- **Properties:**
  - `portfolioName` (String) - Portfolio identifier
  - `currentValue` (Decimal) - Current worth
  - `previousValue` (Decimal) - Previous period value
  - `changeAmount` (Decimal) - Dollar change
  - `changePercentage` (Decimal) - Percentage change
- **Usage:** Performance tracking and trends

---

## 🎯 **Interview Key Points**

### **Architecture Benefits**
1. **Service Layer Separation** - Business logic isolated from UI
2. **Single API Call Optimization** - Comprehensive endpoint vs multiple calls
3. **Metadata-Driven** - Configurable field mappings
4. **Async Processing** - Queueable for large datasets
5. **Type Safety** - DTOs prevent runtime errors

### **Salesforce Best Practices Demonstrated**
1. **Security** - WITH SECURITY_ENFORCED, with sharing
2. **Performance** - Bulkification, single API calls
3. **Scalability** - Job chaining, batch processing
4. **Maintainability** - Service layers, clean separation
5. **Testing** - Comprehensive mock coverage

### **Technical Decisions Explained**
1. **Why Queueable over @future?** - Better control, job chaining, return types
2. **Why comprehensive API?** - Reduces callout limits, better performance
3. **Why DTOs?** - Type safety, clean UI contracts
4. **Why external IDs?** - Idempotent operations, data integrity
5. **Why service layers?** - Reusability, separation of concerns

---

## 🚀 **Demo Flow for Presentation**

1. **Show Architecture** - Explain service layer pattern
2. **Demo Dashboard** - Real-time data display
3. **Trigger Sync** - Show async processing
4. **Explain Performance** - Single API call optimization  
5. **Show Tests** - Comprehensive coverage with mocks

Ready for your interview! 🎯