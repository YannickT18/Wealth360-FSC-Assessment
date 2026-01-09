# Named Credential Setup Guide

## Step 1: Create External Credential

1. In Salesforce Setup, search for **"Named Credentials"**
2. Click on **"External Credentials"** tab
3. Click **"New"**
4. Fill in:
   - **Label**: `Investment Portfolio API`
   - **Name**: `InvestmentPortfolioAPI`
   - **Authentication Protocol**: `No Authentication` (since it's a mock API)
5. Click **"Save"**

## Step 2: Create Named Credential

1. Go to **"Named Credentials"** tab
2. Click **"New"**
3. Select **"Named Credential"** (not Legacy)
4. Fill in:
   - **Label**: `Investment Portfolio API`
   - **Name**: `InvestmentPortfolioAPI`
   - **URL**: `https://your-mock-server-url.mock.pstmn.io` (Replace with your Postman mock URL)
   - **External Credential**: Select `InvestmentPortfolioAPI`
5. Under **"Callout Options"**:
   - Check **"Allow Formulas in HTTP Header"**
   - Check **"Allow Formulas in HTTP Body"**
6. Click **"Save"**

## Step 3: Add Permission Set (if needed)

1. Create or edit a Permission Set
2. Add **"External Credential Principal Access"** for `InvestmentPortfolioAPI`
3. Assign to users who need access

## Step 4: Test the Named Credential

In Developer Console, run this anonymous Apex:

```apex
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:InvestmentPortfolioAPI/api/v1/portfolios?accountId=test123');
req.setMethod('GET');
req.setHeader('Content-Type', 'application/json');

Http http = new Http();
HttpResponse res = http.send(req);

System.debug('Status Code: ' + res.getStatusCode());
System.debug('Response Body: ' + res.getBody());
```

Expected output:
- Status Code: 200
- Response should show your portfolio JSON data

## Alternative: Legacy Named Credential (Simpler for Mock APIs)

If you have issues with the new Named Credential, use Legacy:

1. Setup → Named Credentials → New Legacy
2. Fill in:
   - **Label**: `Investment Portfolio API`
   - **Name**: `InvestmentPortfolioAPI`
   - **URL**: `https://your-mock-server-url.mock.pstmn.io`
   - **Identity Type**: `Anonymous`
   - **Authentication Protocol**: `No Authentication`
3. Save

---

**Your Mock Server URL**: _[Paste here after creating in Postman]_
