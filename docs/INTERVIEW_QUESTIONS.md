# Wealth360 Technical Interview Questions & Answers

## Architecture & Design Patterns

### Q1: Explain the overall architecture of your Wealth360 solution.

**Answer:**
The Wealth360 solution follows a layered architecture with clear separation of concerns:

- **Presentation Layer**: Lightning Web Component (wealth360Dashboard) with @AuraEnabled methods
- **Controller Layer**: CTRL_Wealth360Dashboard handles LWC interactions and data presentation
- **Service Layer**: 
  - SRV_InvestmentPortfolioAPI for external API integration
  - SRV_PortfolioUpdate for business logic and data synchronization
- **Data Transfer Layer**: WRP_Wealth360Dashboard wrapper classes for clean data contracts
- **Configuration Layer**: Custom Metadata Types (Wealth360_Field_Mapping__mdt) for flexible field mapping

This architecture ensures maintainability, testability, and follows Salesforce best practices with proper separation between API integration, business logic, and presentation.

### Q2: Why did you choose to separate API integration and business logic into different service classes?

**Answer:**
I separated SRV_InvestmentPortfolioAPI and SRV_PortfolioUpdate to follow the Single Responsibility Principle:

- **SRV_InvestmentPortfolioAPI**: Focuses solely on external API communication, HTTP callouts, and response parsing
- **SRV_PortfolioUpdate**: Handles Salesforce-specific business logic, field mapping, and data synchronization

Benefits:
- **Maintainability**: Changes to API endpoints don't affect business logic
- **Testability**: Can mock API responses independently of business logic
- **Reusability**: Business logic can be used with different data sources
- **Security**: Clear boundaries for external vs internal data handling

## API Integration & Performance

### Q3: How did you optimize the API integration for performance?

**Answer:**
I transformed multiple API callouts into a single comprehensive request:

**Before**: Multiple callouts for portfolios, holdings, and transactions
**After**: Single `getAllPortfolioDataForSync()` call returning `ComprehensivePortfolioData`

**Benefits:**
- Reduced API call limits consumption (critical in Salesforce)
- Improved performance by eliminating network latency from multiple requests
- Simplified error handling with single transaction boundary
- Better data consistency as all data comes from same API snapshot

**Implementation**: Created a comprehensive wrapper class that bundles all required data, then processes it in a single Salesforce transaction.

### Q4: Explain your approach to handling API security and authentication.

**Answer:**
I implemented secure API integration using Salesforce Named Credentials:

- **Named Credential**: `callout:Wealth360_Investment_API` configured in Setup
- **Benefits**:
  - Centralized credential management
  - No hardcoded secrets in code
  - Automatic token management
  - Per-user or per-org authentication options
  - Certificate-based authentication support

**Code Example**:
```apex
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:Wealth360_Investment_API/portfolios/comprehensive');
req.setMethod('GET');
req.setHeader('Content-Type', 'application/json');
```

The Named Credential handles all authentication headers automatically.

## Custom Metadata & Configuration

### Q5: Why did you implement metadata-driven field mapping instead of hardcoded mappings?

**Answer:**
Metadata-driven configuration provides significant business and technical advantages:

**Business Benefits**:
- **Flexibility**: Administrators can modify field mappings without code deployment
- **Speed**: Changes are immediate, no development cycle required
- **Cost**: Reduces development time for mapping changes

**Technical Benefits**:
- **Maintainability**: No code changes needed for field mapping modifications
- **Scalability**: Easy to add new object types or fields
- **Environment Management**: Different mappings can exist per environment

**Implementation**:
```apex
// Custom Metadata Type: Wealth360_Field_Mapping__mdt
// Fields: Object_Type__c, API_Field_Name__c, Salesforce_Field_Name__c, Data_Type__c

Map<String, Wealth360_Field_Mapping__mdt> mappings = 
    Wealth360_Field_Mapping__mdt.getAll();
```

**Example Records**:
- Portfolio: `api_balance` → `TotalAssetValue__c` (Decimal)
- Holding: `market_value` → `FinServ__MarketValue__c` (Decimal)

### Q6: How does your metadata-driven field mapping handle data type conversion?

**Answer:**
The field mapping system includes intelligent data type conversion:

```apex
private static Object convertValue(String value, String dataType) {
    if (String.isBlank(value)) return null;
    
    switch on dataType.toLowerCase() {
        when 'decimal', 'currency' {
            return Decimal.valueOf(value);
        }
        when 'integer' {
            return Integer.valueOf(value);
        }
        when 'date' {
            return Date.valueOf(value);
        }
        when 'datetime' {
            return Datetime.valueOf(value);
        }
        when 'boolean' {
            return Boolean.valueOf(value);
        }
        when else {
            return value; // String
        }
    }
}
```

This ensures type safety and prevents runtime exceptions when mapping API data to Salesforce fields.

## Financial Services Cloud

### Q7: What Financial Services Cloud objects did you work with and why?

**Answer:**
I leveraged core FSC objects for investment portfolio management:

- **FinServ__FinancialAccount__c**: Represents investment accounts/portfolios
  - Used for: Portfolio-level data, account aggregation
  - Key fields: `TotalAssetValue__c`, `FinServ__PrimaryOwner__c`

- **FinServ__FinancialHolding__c**: Individual investment positions
  - Used for: Asset allocation, portfolio composition
  - Key fields: `FinServ__MarketValue__c`, `FinServ__AssetCategory__c`

- **FinServ__FinancialAccountTransaction__c**: Transaction history
  - Used for: Recent activity, transaction tracking
  - Key fields: `FinServ__Amount__c`, `FinServ__TransactionDate__c`

These objects provide a complete investment management data model with built-in relationships and FSC-specific functionality.

### Q8: How did you ensure data security and field-level security in your solution?

**Answer:**
I implemented multiple layers of security following Salesforce best practices:

1. **Sharing Model**: Used `with sharing` on all Apex classes
2. **SOQL Security**: Added `WITH SECURITY_ENFORCED` to all queries
3. **Field Security**: Applied `Security.stripInaccessible()` for field-level security
4. **User Permissions**: Leveraged FSC permission sets and profiles

**Example Implementation**:
```apex
public with sharing class CTRL_Wealth360Dashboard {
    
    @AuraEnabled(cacheable=true)
    public static List<WRP_Wealth360Dashboard.TransactionData> getRecentTransactions(Id accountId, Integer limitCount) {
        List<FinServ__FinancialAccountTransaction__c> transactions = [
            SELECT Id, Name, FinServ__TransactionType__c, FinServ__Amount__c
            FROM FinServ__FinancialAccountTransaction__c
            WHERE FinServ__FinancialAccount__c IN :financialAccountIds
            WITH SECURITY_ENFORCED
            ORDER BY FinServ__TransactionDate__c DESC
        ];
        
        SObjectAccessDecision decision = Security.stripInaccessible(
            AccessType.READABLE, transactions
        );
        
        // Process stripped records...
    }
}
```

## Testing & Quality Assurance

### Q9: Describe your testing strategy for this solution.

**Answer:**
I implemented comprehensive testing covering all layers:

**1. Unit Tests**:
- Controller tests: `CTRL_Wealth360Dashboard_Test.cls`
- Service tests: `SRV_InvestmentPortfolio_Test.cls`
- Wrapper tests: `WRP_Wealth360Dashboard_Test.cls`

**2. Mock Framework**:
```apex
@IsTest
global class MOCK_InvestmentPortfolioAPI implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(JSON.serialize(createMockData()));
        res.setStatusCode(200);
        return res;
    }
}
```

**3. Test Data Factory**:
- `TEST_DataFactory.cls` for consistent test data creation
- Uses @TestSetup for efficient data creation

**4. Coverage Strategy**:
- Positive and negative test cases
- Exception handling verification
- Edge cases (empty data, null values)
- Security testing (field access, sharing)

### Q10: How do you handle error scenarios and provide meaningful user feedback?

**Answer:**
I implemented comprehensive error handling at multiple levels:

**1. API Level**:
```apex
if (response.getStatusCode() != 200) {
    throw new CalloutException('API Error: ' + response.getStatus());
}
```

**2. Controller Level**:
```apex
try {
    // Business logic
    return data;
} catch (Exception e) {
    throw new AuraHandledException('User-friendly message: ' + e.getMessage());
}
```

**3. LWC Level**:
```javascript
// Handle @AuraEnabled method errors
.catch(error => {
    this.showToast('Error', error.body.message, 'error');
});
```

**4. Wrapper Response Pattern**:
```apex
public class ApiResponse {
    @AuraEnabled public Boolean success { get; set; }
    @AuraEnabled public String message { get; set; }
    @AuraEnabled public Object data { get; set; }
    @AuraEnabled public String errorCode { get; set; }
}
```

## Lightning Web Components

### Q11: Explain the LWC implementation for your dashboard.

**Answer:**
The `wealth360Dashboard` LWC uses modern Salesforce patterns:

**1. Wire Services for Caching**:
```javascript
@wire(getTotalInvestmentValue, { accountId: '$recordId' })
wiredTotalValue({ error, data }) {
    if (data) {
        this.totalValue = data;
    }
}
```

**2. Reactive Properties**:
```javascript
@api recordId; // Account ID from record page
@track assetAllocation = [];
@track recentTransactions = [];
```

**3. Error Handling**:
```javascript
handleSyncPortfolio() {
    syncPortfolioData({ accountId: this.recordId })
        .then(result => {
            this.showToast('Success', 'Portfolio synced successfully', 'success');
            return refreshApex(this.wiredTotalValue);
        })
        .catch(error => {
            this.showToast('Error', error.body.message, 'error');
        });
}
```

### Q12: How did you optimize the LWC for performance?

**Answer:**
I implemented several performance optimizations:

**1. Cacheable Methods**: Used `@AuraEnabled(cacheable=true)` for read-only operations
**2. Wire Service Caching**: Leveraged automatic LDS caching
**3. Conditional Rendering**: Used `if:true` to avoid unnecessary DOM rendering
**4. Event Debouncing**: Prevented excessive API calls during user interaction
**5. Efficient Queries**: Used aggregate queries and LIMIT clauses

**Example**:
```apex
@AuraEnabled(cacheable=true)
public static Decimal getTotalInvestmentValue(Id accountId) {
    AggregateResult[] results = [
        SELECT SUM(TotalAssetValue__c) totalValue
        FROM FinServ__FinancialAccount__c
        WHERE FinServ__PrimaryOwner__c = :accountId
        WITH SECURITY_ENFORCED
    ];
    return (Decimal)results[0].get('totalValue') ?? 0;
}
```

## Deployment & DevOps

### Q13: How would you deploy this solution to production?

**Answer:**
I would follow a structured deployment approach:

**1. Deployment Package**:
- Custom Metadata Types and records
- Apex classes with proper dependencies
- LWC components
- Permission sets
- Named Credentials (configured separately per environment)

**2. Deployment Order**:
```bash
# Deploy metadata structure first
sfdx force:source:deploy -p force-app/main/default/objects

# Deploy Apex classes
sfdx force:source:deploy -p force-app/main/default/classes

# Deploy LWC
sfdx force:source:deploy -p force-app/main/default/lwc

# Deploy custom metadata records
sfdx force:source:deploy -p force-app/main/default/customMetadata
```

**3. Post-Deployment**:
- Configure Named Credentials
- Assign permission sets
- Run manual testing
- Monitor logs for any issues

**4. Rollback Strategy**: Maintain previous version packages for quick rollback if needed.

### Q14: What monitoring and maintenance considerations are important for this solution?

**Answer:**
**1. API Monitoring**:
- Monitor API call limits and usage
- Set up alerts for API failures
- Track response times and performance

**2. Data Quality**:
- Monitor sync job success rates
- Validate data accuracy between external API and Salesforce
- Set up automated data quality checks

**3. User Adoption**:
- Track dashboard usage via Salesforce Analytics
- Monitor user feedback and support cases
- Regular training and documentation updates

**4. Performance Monitoring**:
- Monitor LWC loading times
- Track SOQL query performance
- Monitor heap size usage in batch processes

**5. Security Reviews**:
- Regular permission audits
- API security assessments
- Data access reviews

---

## Practice Tips:

1. **Be Specific**: Always provide concrete examples from your implementation
2. **Show Business Value**: Connect technical decisions to business benefits
3. **Demonstrate Best Practices**: Highlight security, performance, and maintainability
4. **Explain Trade-offs**: Discuss why you chose one approach over alternatives
5. **Show Growth Mindset**: Mention areas for future enhancement or optimization

Good luck with your interview! 🚀