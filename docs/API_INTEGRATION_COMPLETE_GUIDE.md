# Wealth360 API Integration Setup Guide

This guide walks you through setting up a complete API integration using Postman Mock Server and Salesforce Named Credentials.

## Overview

The integration flow:
1. **Postman Mock Server** → Simulates external Investment Portfolio API
2. **Salesforce Named Credential** → Securely connects to the mock API
3. **SRV_InvestmentPortfolioAPI** → API integration service for HTTP callouts
4. **SRV_PortfolioUpdate** → Business logic service for data synchronization
5. **DTO_Wealth360Dashboard** → Data Transfer Objects for clean data transfer
6. **CTRL_Wealth360Dashboard** → Controller that orchestrates services
7. **wealth360Dashboard LWC** → UI that displays the data

### Architecture Benefits:
- **Single API Call**: Optimized from 3 separate calls to 1 comprehensive request
- **Metadata-Driven**: Field mappings configured via Custom Metadata Types
- **Service Separation**: Clear boundaries between API integration and business logic
- **Type Safety**: Strongly typed wrapper classes for data contracts

---

## Part 1: Create Postman Mock Server

### 1.1 Create Collection in Postman

1. Open Postman Desktop App
2. Click **"New"** → **"Collection"**
3. Name: `Investment Portfolio API`
4. Save

### 1.2 Add Request #1: Get Portfolios

1. Click **"Add request"** in the collection
2. Configure:
   - **Name**: `Get Portfolios`
   - **Method**: `GET`
   - **URL**: `{{url}}/api/v1/portfolios`
   - **Params**: Add query parameter `accountId` with value `{{accountId}}`
3. Click **"Save"**
4. Click **"Add Example"**
5. In the example:
   - **Status**: `200 OK`
   - **Body** (select "Raw" and "JSON"):
```json
{
  "success": true,
  "portfolios": [
    {
      "portfolioId": "PORT-001",
      "name": "Retirement Portfolio",
      "totalValue": 750000.00,
      "currency": "USD",
      "lastUpdated": "2025-12-03T10:00:00Z",
      "accountType": "Investment",
      "status": "Active"
    },
    {
      "portfolioId": "PORT-002",
      "name": "Investment Portfolio",
      "totalValue": 450000.00,
      "currency": "USD",
      "lastUpdated": "2025-12-03T10:00:00Z",
      "accountType": "Investment",
      "status": "Active"
    },
    {
      "portfolioId": "PORT-003",
      "name": "Education Savings",
      "totalValue": 125000.00,
      "currency": "USD",
      "lastUpdated": "2025-12-03T10:00:00Z",
      "accountType": "Investment",
      "status": "Active"
    }
  ]
}
```
6. Save the example

### 1.3 Add Request #2: Get Holdings

1. Add new request
2. Configure:
   - **Name**: `Get Holdings`
   - **Method**: `GET`
   - **URL**: `{{url}}/api/v1/portfolios/:portfolioId/holdings`
   - **Path Variables**: `portfolioId` = `PORT-001`
3. Add Example with Body:
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
      "pricePerUnit": 350.00,
      "lastUpdated": "2025-12-03T10:00:00Z"
    },
    {
      "holdingId": "HOLD-002",
      "portfolioId": "PORT-001",
      "assetCategory": "Bonds",
      "assetName": "US Treasury Bonds",
      "currentValue": 225000.00,
      "percentOfPortfolio": 30.00,
      "quantity": 500,
      "pricePerUnit": 450.00,
      "lastUpdated": "2025-12-03T10:00:00Z"
    },
    {
      "holdingId": "HOLD-003",
      "portfolioId": "PORT-001",
      "assetCategory": "Cash",
      "assetName": "Money Market",
      "currentValue": 100000.00,
      "percentOfPortfolio": 13.33,
      "quantity": 100000,
      "pricePerUnit": 1.00,
      "lastUpdated": "2025-12-03T10:00:00Z"
    },
    {
      "holdingId": "HOLD-004",
      "portfolioId": "PORT-001",
      "assetCategory": "Stocks",
      "assetName": "International Equities",
      "currentValue": 75000.00,
      "percentOfPortfolio": 10.00,
      "quantity": 250,
      "pricePerUnit": 300.00,
      "lastUpdated": "2025-12-03T10:00:00Z"
    }
  ]
}
```

### 1.4 Add Request #3: Get Comprehensive Data (Single Call)

1. Add new request
2. Configure:
   - **Name**: `Get Comprehensive Portfolio Data`
   - **Method**: `GET`
   - **URL**: `{{url}}/api/v1/portfolios/comprehensive`
   - **Params**: Add query parameter `accountId` with value `{{accountId}}`
3. Add Example with Body:
```json
{
  "success": true,
  "portfolios": [
    {
      "portfolioId": "PORT-001",
      "name": "Retirement Portfolio",
      "totalValue": 750000.00,
      "currency": "USD",
      "lastUpdated": "2025-12-03T10:00:00Z",
      "accountType": "Investment",
      "status": "Active",
      "holdings": [
        {
          "holdingId": "HOLD-001",
          "assetCategory": "Stocks",
          "assetName": "US Equities",
          "currentValue": 350000.00,
          "quantity": 1000,
          "pricePerUnit": 350.00
        }
      ],
      "transactions": [
        {
          "transactionId": "TXN-001",
          "type": "Buy",
          "amount": 5000.00,
          "transactionDate": "2025-11-28",
          "status": "Completed",
          "description": "Stock Purchase"
        }
      ]
    }
  ]
}
```

### 1.5 Add Request #4: Get Transactions (Legacy)

1. Add new request
2. Configure:
   - **Name**: `Get Transactions`
   - **Method**: `GET`
   - **URL**: `{{url}}/api/v1/portfolios/:portfolioId/transactions`
   - **Path Variables**: `portfolioId` = `PORT-001`
   - **Query Params**: `startDate`, `endDate` (optional)
3. Add Example with Body:
```json
{
  "success": true,
  "transactions": [
    {
      "transactionId": "TXN-001",
      "portfolioId": "PORT-001",
      "type": "Buy",
      "amount": 5000.00,
      "transactionDate": "2025-11-28",
      "status": "Completed",
      "description": "Stock Purchase - US Equities"
    },
    {
      "transactionId": "TXN-002",
      "portfolioId": "PORT-001",
      "type": "Sell",
      "amount": 3000.00,
      "transactionDate": "2025-11-23",
      "status": "Completed",
      "description": "Stock Sale - International Equities"
    },
    {
      "transactionId": "TXN-003",
      "portfolioId": "PORT-001",
      "type": "Dividend",
      "amount": 500.00,
      "transactionDate": "2025-11-18",
      "status": "Completed",
      "description": "Quarterly Dividend Payment"
    },
    {
      "transactionId": "TXN-004",
      "portfolioId": "PORT-001",
      "type": "Buy",
      "amount": 10000.00,
      "transactionDate": "2025-11-13",
      "status": "Completed",
      "description": "Bond Purchase - US Treasury"
    },
    {
      "transactionId": "TXN-005",
      "portfolioId": "PORT-001",
      "type": "Deposit",
      "amount": 2500.00,
      "transactionDate": "2025-11-08",
      "status": "Completed",
      "description": "Cash Deposit"
    }
  ]
}
```

### 1.6 Create Mock Server

1. Right-click on the collection → **"Mock collection"**
2. Name: `Investment Portfolio Mock`
3. Check **"Save the mock server URL as an environment variable"**
4. Click **"Create Mock Server"**
5. **COPY THE MOCK URL** - looks like: `https://xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.mock.pstmn.io`

---

## Part 2: Configure Salesforce Named Credential

### 2.1 Setup → Named Credentials

1. In Salesforce Setup, search: **"Named Credentials"**
2. Click **"New Legacy"** (easier for mock APIs)
3. Fill in:
   - **Label**: `Wealth360 Investment API`
   - **Name**: `Wealth360_Investment_API`
   - **URL**: `https://your-mock-url.mock.pstmn.io` ← Paste your Postman mock URL
   - **Identity Type**: `Anonymous`
   - **Authentication Protocol**: `No Authentication`
   - **Generate Authorization Header**: Unchecked
   - **Allow Merge Fields in HTTP Header**: Checked
   - **Allow Merge Fields in HTTP Body**: Checked
4. Click **"Save"**

### 2.2 Test Named Credential

Open Developer Console → Execute Anonymous:

```apex
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:Wealth360_Investment_API/api/v1/portfolios/comprehensive?accountId=test123');
req.setMethod('GET');
req.setHeader('Content-Type', 'application/json');

Http http = new Http();
HttpResponse res = http.send(req);

System.debug('Status: ' + res.getStatusCode());
System.debug('Body: ' + res.getBody());
```

**Expected Result**: Status 200 with JSON portfolio data

---

## Part 3: Configure Custom Metadata for Field Mapping

### 3.1 Deploy Custom Metadata Type

The solution uses metadata-driven field mapping for flexibility:

1. **Wealth360_Field_Mapping__mdt** - Custom Metadata Type
2. **Field mapping records** - Configure API field to Salesforce field mappings

### 3.2 Sample Metadata Records

Create these Custom Metadata records in Setup:

| Label | Object Type | API Field Name | Salesforce Field Name | Data Type |
|-------|-------------|----------------|----------------------|----------|
| Portfolio Balance | Portfolio | totalValue | TotalAssetValue__c | Decimal |
| Portfolio Name | Portfolio | name | Name | String |
| Holding Market Value | Holding | currentValue | FinServ__MarketValue__c | Decimal |
| Holding Asset Category | Holding | assetCategory | FinServ__AssetCategory__c | String |
| Transaction Amount | Transaction | amount | FinServ__Amount__c | Decimal |
| Transaction Type | Transaction | type | FinServ__TransactionType__c | String |

## Part 4: Deploy Updated Code

The code architecture includes:

1. **CTRL_Wealth360Dashboard.cls** - Controller orchestrating services
2. **SRV_InvestmentPortfolioAPI.cls** - API integration service
3. **SRV_PortfolioUpdate.cls** - Business logic and data sync service
4. **DTO_Wealth360Dashboard.cls** - Data Transfer Objects for clean data handling
5. **Wealth360_Field_Mapping__mdt** - Custom Metadata Type
6. **wealth360Dashboard** LWC - UI component

### Deploy Command:

```powershell
sf project deploy start --source-dir force-app --target-org yannick@bluesky.sandbox
```

---

## Part 5: Test the Integration

1. Go to a Person Account in Salesforce (e.g., Lebron James)
2. View the **Wealth360 Portfolio Dashboard** component
3. Click **"Sync Portfolio"** button
4. Watch the data populate from the Postman Mock API!

 with single callout instead of multiple

---

## Troubleshooting

### Error: "Unauthorized endpoint"
- Solution: Add the mock URL to Remote Site Settings
  - Setup → Remote Site Settings → New
  - Name: `Postman_Mock`
  - URL: Your mock server URL
  - Active: ✓

### Error: "API Error: null"
- Check Named Credential name is exactly `Wealth360_Investment_API`
- Test the callout in Developer Console
- Verify comprehensive endpoint `/api/v1/portfolios/comprehensive` exists

### Field mapping not working
- Verify Custom Metadata Type `Wealth360_Field_Mapping__mdt` is deployed
- Check metadata records match API field names exactly
- Review data type conversions in `SRV_PortfolioUpdate.convertValue()`

### No data appears
- Check browser console for errors
- Verify mock server is running in Postman
- Test each endpoint directly in Postman

---
