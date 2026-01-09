# Wealth360 - Technical Design Document

## Executive Summary
Wealth360 is a Financial Services Cloud (FSC) solution that provides financial advisors with a comprehensive 360-degree view of client investment portfolios by integrating external investment data with Salesforce's standard FSC objects.

**Version:** 1.0  
**Date:** November 22, 2025  
**Author:** Wealth360 Assessment Team

---

## 1. Architecture Overview

### 1.1 System Architecture Diagram
```
┌─────────────────────────────────────────────────────────────────┐
│                    Wealth360 Dashboard (LWC)                    │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────────────┐  │
│  │ Total Value  │  │ Asset Alloc  │  │ Recent Transactions │  │
│  │   Metrics    │  │  Pie Chart   │  │     DataTable       │  │
│  └──────────────┘  └──────────────┘  └─────────────────────┘  │
└────────────────────────────┬────────────────────────────────────┘
                             │ @wire / @AuraEnabled
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│            CTRL_Wealth360Dashboard (with sharing)                │
│  - getTotalInvestmentValue()   - getAssetAllocation()           │
│  - getRecentTransactions()     - syncPortfolioData()            │
└────────────────────────────┬────────────────────────────────────┘
                             │
              ┌──────────────┴──────────────┐
              ▼                             ▼
┌──────────────────────────┐    ┌──────────────────────────┐
│  FSC Standard Objects    │    │   QUE_PortfolioSync      │
│  - FinancialAccount__c   │    │  (Queueable + Callouts)  │
│  - FinancialHolding__c   │    └───────────┬──────────────┘
│  - FinancialAccount      │                │
│    Transaction__c        │                ▼
└──────────────────────────┘    ┌──────────────────────────┐
                                │ SVC_InvestmentPortfolio  │
                                │  - HTTP Callouts         │
                                │  - Retry Logic           │
                                │  - Error Handling        │
                                └───────────┬──────────────┘
                                            │ Named Credential
                                            ▼
                        ┌────────────────────────────────────┐
                        │  External Investment Portfolio API  │
                        │   (Mock: MOCK_InvestmentPortfolioAPI)│
                        └────────────────────────────────────┘
```

### 1.2 Component Diagram
```
┌─────────────────────────────────────────────────────────────┐
│                      Presentation Layer                      │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  wealth360Dashboard (LWC)                              │ │
│  │  - wealth360Dashboard.js                               │ │
│  │  - wealth360Dashboard.html                             │ │
│  │  - wealth360Dashboard.css                              │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                      Controller Layer                        │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  CTRL_Wealth360Dashboard                               │ │
│  │  - @AuraEnabled(cacheable=true) methods                │ │
│  │  - Security.stripInaccessible()                        │ │
│  │  - WITH SECURITY_ENFORCED                              │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                      Service Layer                           │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  SVC_InvestmentPortfolioService                        │ │
│  │  - HTTP callouts with retry logic                      │ │
│  │  - Response parsing                                     │ │
│  │  - Named Credential usage                              │ │
│  └────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  QUE_PortfolioSync (Queueable + AllowsCallouts)        │ │
│  │  - Async bulk processing                               │ │
│  │  - Job chaining                                         │ │
│  │  - Data transformation                                  │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                        Data Layer                            │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  FSC Standard Objects (with custom fields)             │ │
│  │  - FinServ__FinancialAccount__c                        │ │
│  │    • ExternalPortfolioId__c (External ID)              │ │
│  │    • LastSyncDate__c                                    │ │
│  │    • TotalAssetValue__c                                │ │
│  │  - FinServ__FinancialHolding__c                        │ │
│  │    • ExternalHoldingId__c (External ID)                │ │
│  │    • PercentOfPortfolio__c                             │ │
│  │  - FinServ__FinancialAccountTransaction__c            │ │
│  │    • ExternalTransactionId__c (External ID)            │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Data Model

### 2.1 FSC Object Relationships
```
Account (Person Account)
    │
    ├─→ FinServ__FinancialAccount__c (Master-Detail via PrimaryOwner__c)
    │       │
    │       ├─→ FinServ__FinancialHolding__c (Master-Detail)
    │       │       • Represents individual securities/assets
    │       │       • Stores asset category, value, percentage
    │       │
    │       └─→ FinServ__FinancialAccountTransaction__c (Master-Detail)
    │               • Represents buy/sell/dividend transactions
    │               • Stores transaction type, amount, date
    │
    └─→ FinServ__FinancialAccountRole__c (Junction for joint accounts)
```

### 2.2 Custom Fields

#### FinServ__FinancialAccount__c
| Field Name | Type | Purpose |
|------------|------|---------|
| ExternalPortfolioId__c | Text(50), External ID, Unique | Maps to external system portfolio ID |
| LastSyncDate__c | DateTime | Tracks last successful sync |
| TotalAssetValue__c | Currency(18,2) | Calculated total of all holdings |

#### FinServ__FinancialHolding__c
| Field Name | Type | Purpose |
|------------|------|---------|
| ExternalHoldingId__c | Text(50), External ID, Unique | Maps to external system holding ID |
| PercentOfPortfolio__c | Percent(5,2) | Percentage of total portfolio value |

#### FinServ__FinancialAccountTransaction__c
| Field Name | Type | Purpose |
|------------|------|---------|
| ExternalTransactionId__c | Text(50), External ID, Unique | Maps to external system transaction ID |

---

## 3. Integration Flow

### 3.1 Portfolio Sync Process
```mermaid
sequenceDiagram
    participant User
    participant LWC
    participant Controller
    participant Queueable
    participant Service
    participant API
    participant Database

    User->>LWC: Click "Sync Portfolio"
    LWC->>Controller: syncPortfolioData(accountId)
    Controller->>Queueable: enqueueJob(QUE_PortfolioSync)
    Controller-->>LWC: Return Job ID
    LWC-->>User: Show success toast

    Queueable->>Service: getPortfolios(accountId)
    Service->>API: HTTP GET /portfolios
    
    alt Success (200)
        API-->>Service: Portfolio JSON
        Service-->>Queueable: APIResponse(success, data)
        Queueable->>Database: Upsert FinancialAccount__c
        Database-->>Queueable: Success
    else Rate Limit (429)
        API-->>Service: Rate limit error
        Service->>Service: Retry with backoff
    else Server Error (5xx)
        API-->>Service: Server error
        Service->>Service: Retry (max 3 attempts)
        Service-->>Queueable: APIResponse(failure, error)
        Queueable->>Queueable: Log error, continue
    end

    Queueable->>Service: getHoldings(portfolioId)
    Service->>API: HTTP GET /holdings
    API-->>Service: Holdings JSON
    Queueable->>Database: Upsert FinancialHolding__c

    Queueable->>Service: getTransactions(portfolioId)
    Service->>API: HTTP GET /transactions
    API-->>Service: Transactions JSON
    Queueable->>Database: Upsert FinancialAccountTransaction__c
```

### 3.2 Data Retrieval Flow
```
LWC (@wire decorator)
    │
    ├─→ @wire(getTotalInvestmentValue)
    │   └─→ SUM(TotalAssetValue__c) WHERE PrimaryOwner = Account
    │
    ├─→ @wire(getAssetAllocation)
    │   └─→ SUM(HoldingValue__c) GROUP BY AssetCategory
    │       └─→ Calculate percentages in Apex
    │
    └─→ @wire(getRecentTransactions)
        └─→ SELECT TOP 10 ORDER BY TransactionDate DESC
```

---

## 4. API Integration

### 4.1 External API Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/v1/portfolios?accountId={id}` | GET | Retrieve all portfolios for account |
| `/api/v1/portfolios/{portfolioId}` | GET | Retrieve single portfolio |
| `/api/v1/portfolios/{portfolioId}/holdings` | GET | Retrieve holdings for portfolio |
| `/api/v1/portfolios/{portfolioId}/transactions` | GET | Retrieve transactions |

### 4.2 API Response Format

**Portfolio Response:**
```json
{
  "success": true,
  "portfolios": [
    {
      "portfolioId": "PORT-001",
      "name": "Retirement Account",
      "totalValue": 750000.00,
      "currency": "USD",
      "lastUpdated": "2025-11-22T10:00:00Z",
      "accountType": "Investment",
      "status": "Active"
    }
  ]
}
```

**Holdings Response:**
```json
{
  "success": true,
  "holdings": [
    {
      "holdingId": "HOLD-001",
      "portfolioId": "PORT-001",
      "assetCategory": "Stocks",
      "assetName": "US Equities",
      "currentValue": 350000.00,
      "percentOfPortfolio": 46.67,
      "quantity": 1000,
      "pricePerUnit": 350.00
    }
  ]
}
```

### 4.3 Error Handling

| Status Code | Retry Strategy | Action |
|-------------|----------------|--------|
| 200-299 | N/A | Process response |
| 429 | Exponential backoff | Retry up to 3 times |
| 500-599 | Exponential backoff | Retry up to 3 times |
| 400-499 (except 429) | No retry | Log error and continue |

---

## 5. Security

### 5.1 Field-Level Security (FLS)
- All SOQL queries use `WITH SECURITY_ENFORCED`
- `Security.stripInaccessible()` used for Transaction queries
- Controller uses `with sharing` keyword

### 5.2 Named Credentials
- External API uses Named Credential: `InvestmentPortfolioAPI`
- Authentication handled at platform level
- No hardcoded credentials in code

### 5.3 Data Access
- Users require Read access to FSC objects
- Custom permission set: `Wealth360_Dashboard_User`
- Profile-based access to LWC component

---

## 6. Performance & Scalability

### 6.1 Governor Limit Considerations

| Resource | Limit | Strategy |
|----------|-------|----------|
| SOQL Queries | 100 | Bulkify queries, use relationship queries |
| DML Statements | 150 | Batch upserts with Database.upsert() |
| Heap Size | 6MB | Stream process large datasets |
| CPU Time | 10,000ms | Offload to Queueable for heavy processing |
| HTTP Callouts | 100 | Chain Queueable jobs for bulk API calls |
| Queueable Jobs | 50 | Batch processing with job chaining |

### 6.2 Bulkification Patterns
- Queueable processes 50 accounts per job
- Database.upsert() with `allOrNone=false` for partial success
- External ID fields enable efficient upserts

### 6.3 Caching Strategy
- LWC uses `@AuraEnabled(cacheable=true)` for read methods
- `@wire` decorator provides automatic caching
- Manual refresh via `refreshApex()`

---

## 7. Testing Strategy

### 7.1 Test Coverage Goals
- **Target:** >85% code coverage
- **Actual:** >90% achieved

### 7.2 Test Data
- **TEST_DataFactory** provides reusable test data methods
- Follows AAA pattern (Arrange, Act, Assert)
- Tests include positive and negative scenarios

### 7.3 HttpCalloutMock
- **MOCK_InvestmentPortfolioAPI** simulates external API
- Supports success and error scenarios
- Configurable status codes for testing

---

## 8. Deployment

### 8.1 Prerequisites
- Financial Services Cloud managed package installed
- Dev Hub enabled for scratch org creation
- Salesforce CLI v2.x

### 8.2 Deployment Steps
```bash
# Create scratch org
sf org create scratch -f config/project-scratch-def.json -a wealth360 -d 30

# Deploy metadata
sf project deploy start

# Assign permission set
sf org assign permset -n Wealth360_Dashboard_User

# Open org
sf org open
```

### 8.3 Post-Deployment Configuration
1. Configure Named Credential for external API
2. Add LWC to Account page layout
3. Configure Financial Services Cloud features
4. Set up sample Households and Financial Accounts

---

## 9. Future Enhancements

### 9.1 Platform Events
- Replace Queueable chaining with Platform Events for better scalability
- Enable real-time updates to dashboard

### 9.2 Einstein Analytics
- Create portfolio performance dashboards
- Predictive analytics for investment trends

### 9.3 Mobile Optimization
- Native mobile app integration
- Offline capabilities for advisors

### 9.4 Additional Integrations
- Multiple investment providers
- Real-time market data feeds
- Document generation for client reports

---

## 10. Appendix

### 10.1 Class Naming Conventions
| Prefix | Purpose | Example |
|--------|---------|---------|
| CTRL_ | Apex Controllers | CTRL_Wealth360Dashboard |
| SVC_ | Service Classes | SVC_InvestmentPortfolioService |
| QUE_ | Queueable Classes | QUE_PortfolioSync |
| MOCK_ | Test Mock Classes | MOCK_InvestmentPortfolioAPI |
| TEST_ | Test Utilities | TEST_DataFactory |

### 10.2 LWC Best Practices Implemented
- Component decomposition
- Error boundary handling
- Loading state management
- Accessibility compliance
- Reactive properties with `@track`
- Wire service for efficient data retrieval

---

**Document End**
