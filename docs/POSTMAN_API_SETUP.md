# Postman Mock API Setup for Investment Portfolio

This guide will help you set up a Postman Mock Server to simulate the external Investment Portfolio API.

## Step 1: Create Postman Collection

1. Open Postman
2. Create a new Collection named "Investment Portfolio API"

## Step 2: Add API Endpoints

### Endpoint 1: Get Portfolios
- **Method**: GET
- **URL**: `/api/v1/portfolios`
- **Query Parameters**: `accountId` (Salesforce Account ID)
- **Response** (Status 200):
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

### Endpoint 2: Get Holdings for a Portfolio
- **Method**: GET
- **URL**: `/api/v1/portfolios/:portfolioId/holdings`
- **Path Variable**: `portfolioId`
- **Response** (Status 200):
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

### Endpoint 3: Get Transactions for a Portfolio
- **Method**: GET
- **URL**: `/api/v1/portfolios/:portfolioId/transactions`
- **Path Variable**: `portfolioId`
- **Query Parameters**: 
  - `startDate` (optional): Format YYYY-MM-DD
  - `endDate` (optional): Format YYYY-MM-DD
- **Response** (Status 200):
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

## Step 3: Create Mock Server

1. In your collection, click on the "..." menu
2. Select "Mock collection"
3. Name it "Investment Portfolio Mock Server"
4. Click "Create Mock Server"
5. Copy the **Mock Server URL** (e.g., `https://xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.mock.pstmn.io`)

## Step 4: Save Examples in Postman

For each endpoint:
1. Send a request
2. Click "Save Response" → "Save as Example"
3. This ensures the mock server returns consistent data

## Step 5: Test Mock Server

Test each endpoint using the mock URL:
```
GET {{mockUrl}}/api/v1/portfolios?accountId=001XXXXXXXXXXXXXXX
GET {{mockUrl}}/api/v1/portfolios/PORT-001/holdings
GET {{mockUrl}}/api/v1/portfolios/PORT-001/transactions
```

## Next Steps

Once your mock server is running:
1. Copy the Mock Server URL
2. We'll configure a Named Credential in Salesforce
3. Update the code to use the real service class with API callouts

---

**Note**: The mock server URL will look like:
`https://xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.mock.pstmn.io`
