# Wealth360 FSC Assessment - Complete Replication Guide

This guide provides step-by-step instructions to replicate all deliverables for the Wealth360 Financial Services Cloud Assessment.

## 📋 Prerequisites

- Salesforce CLI installed
- VS Code with Salesforce Extension Pack
- Git installed
- Postman Desktop App
- Node.js (for LWC development)
- Access to Salesforce org with Financial Services Cloud

---

## 🗂️ Step 1: Create SFDX Project Structure

### 1.1 Initialize Project

```bash
# Create project directory
mkdir Wealth360-FSC-Assessment
cd Wealth360-FSC-Assessment

# Initialize SFDX project
sf project generate --name Wealth360-FSC-Assessment

# Initialize Git repository
git init
```

### 1.2 Create Project Structure

```bash
# Create documentation folder
mkdir docs

# Create Postman collections folder
mkdir postman

# Create scripts folder
mkdir scripts/apex

# Verify structure
tree /f
```

Expected structure:
```
Wealth360-FSC-Assessment/
├── README.md
├── sfdx-project.json
├── package.json
├── GIT_SETUP.md
├── docs/
├── postman/
├── scripts/
│   └── apex/
├── config/
│   └── project-scratch-def.json
├── force-app/
│   └── main/
│       └── default/
└── manifest/
    └── package.xml
```

### 1.3 Configure sfdx-project.json

```json
{
  "packageDirectories": [
    {
      "path": "force-app",
      "default": true
    }
  ],
  "name": "Wealth360-FSC-Assessment",
  "namespace": "",
  "sfdcLoginUrl": "https://login.salesforce.com",
  "sourceApiVersion": "60.0"
}
```

---

## 🏗️ Step 2: Create Data Model & Custom Metadata

### 2.1 Custom Fields for Financial Services Cloud Objects

Create these custom fields:

#### FinServ__FinancialAccount__c
```xml
<!-- force-app/main/default/objects/FinServ__FinancialAccount__c/fields/ExternalPortfolioId__c.field-meta.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>ExternalPortfolioId__c</fullName>
    <externalId>true</externalId>
    <label>External Portfolio ID</label>
    <length>50</length>
    <required>false</required>
    <trackFeedHistory>false</trackFeedHistory>
    <type>Text</type>
    <unique>false</unique>
</CustomField>
```

```xml
<!-- force-app/main/default/objects/FinServ__FinancialAccount__c/fields/TotalAssetValue__c.field-meta.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>TotalAssetValue__c</fullName>
    <label>Total Asset Value</label>
    <precision>18</precision>
    <required>false</required>
    <scale>2</scale>
    <trackFeedHistory>false</trackFeedHistory>
    <type>Currency</type>
</CustomField>
```

#### Custom Objects (if needed)
```bash
# Generate custom objects
sf sobject generate --label "Investment" --plural "Investments"
sf sobject generate --label "Transaction" --plural "Transactions"
```

### 2.2 Custom Metadata Type

```xml
<!-- force-app/main/default/objects/Wealth360_Field_Mapping__mdt/Wealth360_Field_Mapping__mdt.object-meta.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>Wealth360 Field Mapping</label>
    <pluralLabel>Wealth360 Field Mappings</pluralLabel>
    <visibility>Public</visibility>
</CustomObject>
```

Create custom fields for the metadata type:
- `Object_Type__c` (Text, 50)
- `API_Field_Name__c` (Text, 100)  
- `Salesforce_Field_Name__c` (Text, 100)
- `Data_Type__c` (Picklist: String, Decimal, Integer, Date, DateTime, Boolean)

### 2.3 Custom Metadata Records

```xml
<!-- force-app/main/default/customMetadata/Wealth360_Field_Mapping.Portfolio_Balance.md-meta.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>Portfolio Balance</label>
    <protected>false</protected>
    <values>
        <field>Object_Type__c</field>
        <value xsi:type="xsd:string">Portfolio</value>
    </values>
    <values>
        <field>API_Field_Name__c</field>
        <value xsi:type="xsd:string">totalValue</value>
    </values>
    <values>
        <field>Salesforce_Field_Name__c</field>
        <value xsi:type="xsd:string">TotalAssetValue__c</value>
    </values>
    <values>
        <field>Data_Type__c</field>
        <value xsi:type="xsd:string">Decimal</value>
    </values>
</CustomMetadata>
```

Create additional records for other field mappings.

---

## 💻 Step 3: Create Apex Classes

### 3.1 Service Layer Classes

#### SRV_InvestmentPortfolioAPI.cls
```apex
/**
 * @description API integration service for Investment Portfolio external API
 * @author Wealth360 Team
 * @date 2026
 */
public with sharing class SRV_InvestmentPortfolioAPI {
    
    private static final String NAMED_CREDENTIAL = 'callout:Wealth360_Investment_API';
    private static final String COMPREHENSIVE_ENDPOINT = '/api/v1/portfolios/comprehensive';
    
    /**
     * @description Get all portfolio data in a single API call
     * @param accountId Account ID to fetch portfolios for
     * @return ComprehensivePortfolioData wrapper with all data
     */
    public static ComprehensivePortfolioData getAllPortfolioDataForSync(Id accountId) {
        HttpRequest request = buildHttpRequest(accountId);
        HttpResponse response = executeRequest(request);
        
        return parseComprehensiveResponse(response);
    }
    
    /**
     * @description Build HTTP request for comprehensive portfolio data
     */
    private static HttpRequest buildHttpRequest(Id accountId) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(NAMED_CREDENTIAL + COMPREHENSIVE_ENDPOINT + '?accountId=' + accountId);
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json');
        request.setTimeout(60000); // 60 seconds
        
        return request;
    }
    
    /**
     * @description Execute HTTP request with error handling
     */
    private static HttpResponse executeRequest(HttpRequest request) {
        Http http = new Http();
        HttpResponse response = http.send(request);
        
        if (response.getStatusCode() != 200) {
            throw new CalloutException('API Error: ' + response.getStatus() + ' - ' + response.getBody());
        }
        
        return response;
    }
    
    /**
     * @description Parse comprehensive API response
     */
    private static ComprehensivePortfolioData parseComprehensiveResponse(HttpResponse response) {
        return (ComprehensivePortfolioData) JSON.deserialize(
            response.getBody(), 
            ComprehensivePortfolioData.class
        );
    }
    
    /**
     * @description Comprehensive portfolio data wrapper
     */
    public class ComprehensivePortfolioData {
        public Boolean success;
        public List<PortfolioData> portfolios;
        
        public ComprehensivePortfolioData() {
            this.portfolios = new List<PortfolioData>();
        }
    }
    
    /**
     * @description Portfolio data with holdings and transactions
     */
    public class PortfolioData {
        public String portfolioId;
        public String name;
        public Decimal totalValue;
        public String currency;
        public String lastUpdated;
        public String accountType;
        public String status;
        public List<HoldingData> holdings;
        public List<TransactionData> transactions;
        
        public PortfolioData() {
            this.holdings = new List<HoldingData>();
            this.transactions = new List<TransactionData>();
        }
    }
    
    public class HoldingData {
        public String holdingId;
        public String assetCategory;
        public String assetName;
        public Decimal currentValue;
        public Decimal quantity;
        public Decimal pricePerUnit;
    }
    
    public class TransactionData {
        public String transactionId;
        public String type;
        public Decimal amount;
        public String transactionDate;
        public String status;
        public String description;
    }
}
```

#### SRV_PortfolioUpdate.cls
```apex
/**
 * @description Business logic service for portfolio data synchronization
 * @author Wealth360 Team
 * @date 2026
 */
public with sharing class SRV_PortfolioUpdate {
    
    /**
     * @description Sync comprehensive portfolio data using metadata-driven field mapping
     */
    public static void syncComprehensivePortfolioData(Id accountId, SRV_InvestmentPortfolioAPI.ComprehensivePortfolioData comprehensiveData) {
        
        List<FinServ__FinancialAccount__c> portfoliosToUpsert = new List<FinServ__FinancialAccount__c>();
        List<FinServ__FinancialHolding__c> holdingsToUpsert = new List<FinServ__FinancialHolding__c>();
        List<FinServ__FinancialAccountTransaction__c> transactionsToUpsert = new List<FinServ__FinancialAccountTransaction__c>();
        
        // Process each portfolio with holdings and transactions
        for (SRV_InvestmentPortfolioAPI.PortfolioData portfolio : comprehensiveData.portfolios) {
            
            // Create/update portfolio
            FinServ__FinancialAccount__c sfPortfolio = createPortfolioRecord(accountId, portfolio);
            portfoliosToUpsert.add(sfPortfolio);
            
            // Create holdings for this portfolio
            for (SRV_InvestmentPortfolioAPI.HoldingData holding : portfolio.holdings) {
                FinServ__FinancialHolding__c sfHolding = createHoldingRecord(portfolio.portfolioId, holding);
                holdingsToUpsert.add(sfHolding);
            }
            
            // Create transactions for this portfolio
            for (SRV_InvestmentPortfolioAPI.TransactionData transaction : portfolio.transactions) {
                FinServ__FinancialAccountTransaction__c sfTransaction = createTransactionRecord(portfolio.portfolioId, transaction);
                transactionsToUpsert.add(sfTransaction);
            }
        }
        
        // Perform DML operations
        performUpsertOperations(portfoliosToUpsert, holdingsToUpsert, transactionsToUpsert);
    }
    
    /**
     * @description Create portfolio record with metadata-driven field mapping
     */
    private static FinServ__FinancialAccount__c createPortfolioRecord(Id accountId, SRV_InvestmentPortfolioAPI.PortfolioData portfolioData) {
        
        FinServ__FinancialAccount__c portfolio = new FinServ__FinancialAccount__c();
        portfolio.FinServ__PrimaryOwner__c = accountId;
        portfolio.FinServ__FinancialAccountType__c = 'Investment';
        portfolio.ExternalPortfolioId__c = portfolioData.portfolioId;
        
        // Apply metadata-driven field mappings
        Map<String, Object> apiData = new Map<String, Object>{
            'name' => portfolioData.name,
            'totalValue' => portfolioData.totalValue,
            'accountType' => portfolioData.accountType,
            'status' => portfolioData.status
        };
        
        applyFieldMappings(portfolio, apiData, 'Portfolio');
        
        return portfolio;
    }
    
    /**
     * @description Apply metadata-driven field mappings
     */
    private static void applyFieldMappings(SObject record, Map<String, Object> apiData, String objectType) {
        
        Map<String, Wealth360_Field_Mapping__mdt> mappings = Wealth360_Field_Mapping__mdt.getAll();
        
        for (Wealth360_Field_Mapping__mdt mapping : mappings.values()) {
            if (mapping.Object_Type__c == objectType && apiData.containsKey(mapping.API_Field_Name__c)) {
                
                Object apiValue = apiData.get(mapping.API_Field_Name__c);
                Object convertedValue = convertValue(String.valueOf(apiValue), mapping.Data_Type__c);
                
                record.put(mapping.Salesforce_Field_Name__c, convertedValue);
            }
        }
    }
    
    /**
     * @description Convert API value to appropriate Salesforce data type
     */
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
    
    // Additional helper methods for holdings and transactions...
}
```

### 3.2 Controller Classes

#### CTRL_Wealth360Dashboard.cls
```apex
/**
 * @description Apex controller for Wealth360 Dashboard LWC
 * @author Wealth360 Assessment  
 * @date 2026
 */
public with sharing class CTRL_Wealth360Dashboard {
    
    @AuraEnabled(cacheable=true)
    public static Decimal getTotalInvestmentValue(Id accountId) {
        try {
            AggregateResult[] results = [
                SELECT SUM(TotalAssetValue__c) totalValue
                FROM FinServ__FinancialAccount__c
                WHERE FinServ__PrimaryOwner__c = :accountId
                AND FinServ__FinancialAccountType__c = 'Investment'
                WITH SECURITY_ENFORCED
            ];
            
            Decimal totalValue = (Decimal)results[0].get('totalValue');
            return totalValue != null ? totalValue : 0;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching total investment value: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String syncPortfolioData(Id accountId) {
        try {
            syncPortfolioDataFromAPI(accountId);
            return 'SUCCESS';
            
        } catch (Exception e) {
            throw new AuraHandledException('Error syncing portfolio data: ' + e.getMessage());
        }
    }
    
    private static void syncPortfolioDataFromAPI(Id accountId) {
        SRV_InvestmentPortfolioAPI.ComprehensivePortfolioData comprehensiveData = 
            SRV_InvestmentPortfolioAPI.getAllPortfolioDataForSync(accountId);
        
        SRV_PortfolioUpdate.syncComprehensivePortfolioData(accountId, comprehensiveData);
    }
    
    // Additional @AuraEnabled methods...
}
```

### 3.3 Wrapper Classes

#### WRP_Wealth360Dashboard.cls
```apex
/**
 * @description Wrapper/DTO classes for Wealth360 Dashboard data transfer
 * @author Wealth360 Team
 * @date 2026
 */
public with sharing class WRP_Wealth360Dashboard {
    
    public class AssetAllocation {
        @AuraEnabled public String category { get; set; }
        @AuraEnabled public Decimal value { get; set; }
        @AuraEnabled public Decimal percentage { get; set; }
        
        public AssetAllocation(String category, Decimal value, Decimal percentage) {
            this.category = category;
            this.value = value;
            this.percentage = percentage;
        }
    }
    
    public class TransactionData {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String type { get; set; }
        @AuraEnabled public Decimal amount { get; set; }
        @AuraEnabled public Date transactionDate { get; set; }
        @AuraEnabled public String status { get; set; }
        
        public TransactionData(FinServ__FinancialAccountTransaction__c txn) {
            this.id = txn.Id;
            this.name = txn.Name;
            this.type = txn.FinServ__TransactionType__c;
            this.amount = txn.FinServ__Amount__c;
            this.transactionDate = txn.FinServ__TransactionDate__c?.date();
            this.status = txn.FinServ__TransactionStatus__c;
        }
    }
    
    public class PortfolioSummary {
        @AuraEnabled public Integer portfolioCount { get; set; }
        @AuraEnabled public Integer holdingsCount { get; set; }
        @AuraEnabled public Decimal totalValue { get; set; }
        
        public PortfolioSummary() {
            this.portfolioCount = 0;
            this.holdingsCount = 0;
            this.totalValue = 0;
        }
    }
}
```

### 3.4 Test Classes

#### TEST_DataFactory.cls
```apex
/**
 * @description Test data factory for creating test records
 */
@IsTest
public class TEST_DataFactory {
    
    public static Account createPersonAccount() {
        return new Account(
            FirstName = 'John',
            LastName = 'Doe',
            RecordTypeId = getPersonAccountRecordTypeId()
        );
    }
    
    public static FinServ__FinancialAccount__c createFinancialAccount(Id accountId) {
        return new FinServ__FinancialAccount__c(
            Name = 'Test Portfolio',
            FinServ__PrimaryOwner__c = accountId,
            FinServ__FinancialAccountType__c = 'Investment',
            TotalAssetValue__c = 100000.00
        );
    }
    
    private static Id getPersonAccountRecordTypeId() {
        return Schema.SObjectType.Account.getRecordTypeInfosByName()
            .get('Person Account').getRecordTypeId();
    }
}
```

#### SRV_InvestmentPortfolioAPI_Test.cls
```apex
/**
 * @description Test class for SRV_InvestmentPortfolioAPI
 */
@IsTest
private class SRV_InvestmentPortfolioAPI_Test {
    
    @TestSetup
    static void makeData() {
        Account testAccount = TEST_DataFactory.createPersonAccount();
        insert testAccount;
    }
    
    @IsTest
    static void testGetAllPortfolioDataForSync() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Test.setMock(HttpCalloutMock.class, new MOCK_InvestmentPortfolioAPI());
        
        Test.startTest();
        SRV_InvestmentPortfolioAPI.ComprehensivePortfolioData result = 
            SRV_InvestmentPortfolioAPI.getAllPortfolioDataForSync(testAccount.Id);
        Test.stopTest();
        
        System.assertNotNull(result);
        System.assertEquals(true, result.success);
        System.assertFalse(result.portfolios.isEmpty());
    }
}
```

#### MOCK_InvestmentPortfolioAPI.cls
```apex
/**
 * @description Mock class for Investment Portfolio API responses
 */
@IsTest
global class MOCK_InvestmentPortfolioAPI implements HttpCalloutMock {
    
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
        
        // Return mock comprehensive data
        String mockResponse = JSON.serialize(createMockComprehensiveData());
        res.setBody(mockResponse);
        
        return res;
    }
    
    private SRV_InvestmentPortfolioAPI.ComprehensivePortfolioData createMockComprehensiveData() {
        SRV_InvestmentPortfolioAPI.ComprehensivePortfolioData data = 
            new SRV_InvestmentPortfolioAPI.ComprehensivePortfolioData();
        
        data.success = true;
        data.portfolios = new List<SRV_InvestmentPortfolioAPI.PortfolioData>();
        
        // Create mock portfolio
        SRV_InvestmentPortfolioAPI.PortfolioData portfolio = 
            new SRV_InvestmentPortfolioAPI.PortfolioData();
        portfolio.portfolioId = 'PORT-001';
        portfolio.name = 'Test Portfolio';
        portfolio.totalValue = 100000.00;
        
        data.portfolios.add(portfolio);
        
        return data;
    }
}
```

---

## ⚡ Step 4: Create Lightning Web Components

### 4.1 Create LWC Component

```bash
# Generate LWC component
sf lightning generate component --name wealth360Dashboard --type lwc
```

#### wealth360Dashboard.js
```javascript
import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

// Import Apex methods
import getTotalInvestmentValue from '@salesforce/apex/CTRL_Wealth360Dashboard.getTotalInvestmentValue';
import getAssetAllocation from '@salesforce/apex/CTRL_Wealth360Dashboard.getAssetAllocation';
import getRecentTransactions from '@salesforce/apex/CTRL_Wealth360Dashboard.getRecentTransactions';
import syncPortfolioData from '@salesforce/apex/CTRL_Wealth360Dashboard.syncPortfolioData';
import getPortfolioSummary from '@salesforce/apex/CTRL_Wealth360Dashboard.getPortfolioSummary';

export default class Wealth360Dashboard extends LightningElement {
    @api recordId; // Account ID from record page
    
    @track totalValue = 0;
    @track assetAllocation = [];
    @track recentTransactions = [];
    @track portfolioSummary = {};
    @track isLoading = false;
    
    // Wire services for caching
    @wire(getTotalInvestmentValue, { accountId: '$recordId' })
    wiredTotalValue(result) {
        this.wiredTotalValueResult = result;
        if (result.data) {
            this.totalValue = result.data;
        }
    }
    
    @wire(getAssetAllocation, { accountId: '$recordId' })
    wiredAssetAllocation({ error, data }) {
        if (data) {
            this.assetAllocation = data;
        }
    }
    
    @wire(getRecentTransactions, { accountId: '$recordId', limitCount: 10 })
    wiredRecentTransactions({ error, data }) {
        if (data) {
            this.recentTransactions = data;
        }
    }
    
    @wire(getPortfolioSummary, { accountId: '$recordId' })
    wiredPortfolioSummary({ error, data }) {
        if (data) {
            this.portfolioSummary = data;
        }
    }
    
    // Handle sync portfolio button
    handleSyncPortfolio() {
        this.isLoading = true;
        
        syncPortfolioData({ accountId: this.recordId })
            .then(result => {
                if (result === 'SUCCESS') {
                    this.showToast('Success', 'Portfolio data synced successfully', 'success');
                    // Refresh wired data
                    return refreshApex(this.wiredTotalValueResult);
                }
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
    
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
    
    get formattedTotalValue() {
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD'
        }).format(this.totalValue || 0);
    }
}
```

#### wealth360Dashboard.html
```html
<template>
    <lightning-card title="Wealth360 Portfolio Dashboard" icon-name="custom:custom18">
        
        <!-- Loading Spinner -->
        <div if:true={isLoading} class="slds-is-relative">
            <lightning-spinner alternative-text="Loading..." size="medium"></lightning-spinner>
        </div>
        
        <!-- Portfolio Summary -->
        <div class="slds-p-horizontal_medium">
            <div class="slds-grid slds-wrap slds-gutters">
                
                <!-- Total Value Card -->
                <div class="slds-col slds-size_1-of-1 slds-medium-size_1-of-3">
                    <div class="summary-card">
                        <h3 class="slds-text-heading_small">Total Investment Value</h3>
                        <p class="slds-text-heading_large slds-text-color_success">{formattedTotalValue}</p>
                    </div>
                </div>
                
                <!-- Portfolio Count -->
                <div class="slds-col slds-size_1-of-1 slds-medium-size_1-of-3">
                    <div class="summary-card">
                        <h3 class="slds-text-heading_small">Portfolios</h3>
                        <p class="slds-text-heading_large">{portfolioSummary.portfolioCount}</p>
                    </div>
                </div>
                
                <!-- Holdings Count -->
                <div class="slds-col slds-size_1-of-1 slds-medium-size_1-of-3">
                    <div class="summary-card">
                        <h3 class="slds-text-heading_small">Holdings</h3>
                        <p class="slds-text-heading_large">{portfolioSummary.holdingsCount}</p>
                    </div>
                </div>
                
            </div>
        </div>
        
        <!-- Sync Button -->
        <div class="slds-p-horizontal_medium slds-p-vertical_small">
            <lightning-button 
                label="Sync Portfolio Data" 
                variant="brand" 
                onclick={handleSyncPortfolio}
                disabled={isLoading}>
            </lightning-button>
        </div>
        
        <!-- Asset Allocation Chart -->
        <div class="slds-p-horizontal_medium" if:true={assetAllocation.length}>
            <h3 class="slds-text-heading_medium slds-p-bottom_small">Asset Allocation</h3>
            <template for:each={assetAllocation} for:item="allocation">
                <div key={allocation.category} class="allocation-item">
                    <div class="slds-grid slds-grid_align-spread">
                        <span>{allocation.category}</span>
                        <span>{allocation.percentage}%</span>
                    </div>
                    <lightning-progress-bar value={allocation.percentage}></lightning-progress-bar>
                </div>
            </template>
        </div>
        
        <!-- Recent Transactions -->
        <div class="slds-p-around_medium" if:true={recentTransactions.length}>
            <h3 class="slds-text-heading_medium slds-p-bottom_small">Recent Transactions</h3>
            <lightning-datatable
                data={recentTransactions}
                columns={transactionColumns}
                key-field="id">
            </lightning-datatable>
        </div>
        
    </lightning-card>
</template>
```

#### wealth360Dashboard.css
```css
.summary-card {
    background: white;
    border: 1px solid #d8dde6;
    border-radius: 0.25rem;
    padding: 1rem;
    text-align: center;
}

.allocation-item {
    margin-bottom: 0.5rem;
}

.slds-progress-bar {
    margin-top: 0.25rem;
}
```

#### wealth360Dashboard.js-meta.xml
```xml
<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>60.0</apiVersion>
    <isExposed>true</isExposed>
    <targets>
        <target>lightning__RecordPage</target>
    </targets>
    <targetConfigs>
        <targetConfig targets="lightning__RecordPage">
            <supportedFormFactors>
                <supportedFormFactor type="Large"/>
                <supportedFormFactor type="Small"/>
            </supportedFormFactors>
        </targetConfig>
    </targetConfigs>
</LightningComponentBundle>
```

---

## 📮 Step 5: Create Postman Collection

### 5.1 Create Collection File

Create `postman/Investment Portfolio API - Complete.postman_collection.json`:

```json
{
	"info": {
		"name": "Investment Portfolio API - Complete",
		"description": "Complete API collection for Wealth360 integration testing",
		"schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
	},
	"item": [
		{
			"name": "Get Comprehensive Portfolio Data",
			"request": {
				"method": "GET",
				"header": [
					{
						"key": "Content-Type",
						"value": "application/json"
					}
				],
				"url": {
					"raw": "{{url}}/api/v1/portfolios/comprehensive?accountId={{accountId}}",
					"host": ["{{url}}"],
					"path": ["api", "v1", "portfolios", "comprehensive"],
					"query": [
						{
							"key": "accountId",
							"value": "{{accountId}}"
						}
					]
				}
			},
			"response": [
				{
					"name": "Success Response",
					"originalRequest": {
						"method": "GET",
						"header": [],
						"url": {
							"raw": "{{url}}/api/v1/portfolios/comprehensive?accountId={{accountId}}",
							"host": ["{{url}}"],
							"path": ["api", "v1", "portfolios", "comprehensive"]
						}
					},
					"status": "OK",
					"code": 200,
					"body": "{\n  \"success\": true,\n  \"portfolios\": [\n    {\n      \"portfolioId\": \"PORT-001\",\n      \"name\": \"Retirement Portfolio\",\n      \"totalValue\": 750000.00,\n      \"currency\": \"USD\",\n      \"lastUpdated\": \"2026-01-08T10:00:00Z\",\n      \"accountType\": \"Investment\",\n      \"status\": \"Active\",\n      \"holdings\": [\n        {\n          \"holdingId\": \"HOLD-001\",\n          \"assetCategory\": \"Stocks\",\n          \"assetName\": \"US Equities\",\n          \"currentValue\": 350000.00,\n          \"quantity\": 1000,\n          \"pricePerUnit\": 350.00\n        }\n      ],\n      \"transactions\": [\n        {\n          \"transactionId\": \"TXN-001\",\n          \"type\": \"Buy\",\n          \"amount\": 5000.00,\n          \"transactionDate\": \"2025-11-28\",\n          \"status\": \"Completed\",\n          \"description\": \"Stock Purchase\"\n        }\n      ]\n    }\n  ]\n}"
				}
			]
		}
	],
	"variable": [
		{
			"key": "url",
			"value": "https://your-mock-url.mock.pstmn.io"
		},
		{
			"key": "accountId",
			"value": "0031234567890123"
		}
	]
}
```

### 5.2 Create Mock Server

1. Import the collection into Postman
2. Right-click collection → "Mock Collection"
3. Name: "Investment Portfolio Mock"
4. Save mock URL for Named Credential configuration

---

## 📚 Step 6: Create Documentation

### 6.1 Main README.md

```markdown
# Wealth360 Financial Services Cloud Assessment

A comprehensive Salesforce Financial Services Cloud solution for investment portfolio management with external API integration.

## 🏗️ Architecture

- **Service Layer**: Separated API integration and business logic
- **Metadata-Driven**: Configurable field mappings via Custom Metadata
- **Performance Optimized**: Single API call instead of multiple requests
- **Type Safe**: Wrapper classes for clean data contracts

## 📁 Project Structure

```
Wealth360-FSC-Assessment/
├── force-app/main/default/
│   ├── classes/                    # Apex classes
│   ├── lwc/wealth360Dashboard/     # Lightning Web Component
│   ├── objects/                    # Custom fields and metadata
│   └── customMetadata/             # Field mapping configuration
├── postman/                        # API testing collections
├── docs/                          # Documentation
└── scripts/                       # Deployment scripts
```

## 🚀 Quick Start

1. **Clone Repository**
   ```bash
   git clone <repository-url>
   cd Wealth360-FSC-Assessment
   ```

2. **Deploy to Org**
   ```bash
   sf project deploy start --source-dir force-app --target-org your-org-alias
   ```

3. **Configure API Integration**
   - Set up Named Credential: `Wealth360_Investment_API`
   - Import Postman collection for mock API
   - Configure Custom Metadata field mappings

4. **Test Integration**
   - Add component to Account record page
   - Click "Sync Portfolio Data"
   - Verify data population

## 🔧 Key Components

- **CTRL_Wealth360Dashboard**: LWC controller
- **SRV_InvestmentPortfolioAPI**: API integration service
- **SRV_PortfolioUpdate**: Business logic service  
- **WRP_Wealth360Dashboard**: Data transfer objects

## 📊 Features

✅ Single API call optimization
✅ Metadata-driven field mapping
✅ Service layer separation
✅ Comprehensive test coverage
✅ Real-time dashboard updates

## 📖 Documentation

See `docs/` folder for detailed guides:
- [API Integration Guide](docs/API_INTEGRATION_COMPLETE_GUIDE.md)
- [Technical Design](docs/TECHNICAL_DESIGN.md)
- [Interview Questions](docs/INTERVIEW_QUESTIONS.md)
```

### 6.2 Additional Documentation Files

Create these files in `docs/` folder:

- `TECHNICAL_DESIGN.md` - Architecture and design decisions
- `DEPLOYMENT_CHECKLIST.md` - Deployment steps and requirements
- `API_INTEGRATION_COMPLETE_GUIDE.md` - Complete API setup guide
- `INTERVIEW_QUESTIONS.md` - Technical interview preparation

---

## 🎬 Step 7: Create Video Walkthrough (Optional)

### 7.1 Video Script Outline

**Duration: 5-7 minutes**

1. **Introduction (30 seconds)**
   - Project overview and objectives
   - Key architecture highlights

2. **Code Walkthrough (2 minutes)**
   - Service layer separation
   - Metadata-driven configuration
   - Wrapper classes and type safety

3. **Live Demo (2-3 minutes)**
   - Navigate to Account record
   - Show dashboard component
   - Demonstrate sync functionality
   - Show data population

4. **Technical Highlights (1-2 minutes)**
   - Single API call optimization
   - Custom metadata configuration
   - Test coverage and mock framework

5. **Conclusion (30 seconds)**
   - Business value and benefits
   - Future enhancements

### 7.2 Recording Setup

**Tools Options:**
- Loom (recommended for easy sharing)
- OBS Studio (for professional recording)
- Zoom (screen share recording)

**Recording Tips:**
- Use 1080p resolution
- Record both screen and audio
- Practice the walkthrough first
- Keep cursor movements smooth
- Speak clearly and at moderate pace

---

## 📦 Step 8: Final Deliverable Assembly

### 8.1 Git Repository Setup

```bash
# Initialize repository
git init
git add .
git commit -m "Initial commit: Wealth360 FSC Assessment"

# Create GitHub repository (optional)
git remote add origin https://github.com/yourusername/Wealth360-FSC-Assessment.git
git push -u origin main
```

### 8.2 Create Release Package

```bash
# Create ZIP file for submission
zip -r Wealth360-FSC-Assessment.zip . -x "*.git*" "node_modules/*" ".sf/*"
```

### 8.3 Deliverables Checklist

✅ **SFDX Project Structure**
- Complete force-app directory
- sfdx-project.json configured
- Package.xml for deployment

✅ **Apex Classes**
- Service layer classes (API integration + business logic)
- Controller classes for LWC
- Wrapper/DTO classes
- Comprehensive test classes with mocks

✅ **LWC Components**
- wealth360Dashboard component
- Complete HTML, JS, CSS, and metadata files
- Proper wire services and error handling

✅ **Data Model & Metadata**
- Custom fields on FSC objects
- Custom Metadata Type for field mappings
- Sample metadata records

✅ **Postman Collection**
- Complete API collection with examples
- Mock server configuration
- Environment variables setup

✅ **Documentation**
- Comprehensive README.md
- Technical design documentation
- API integration guide
- Interview preparation questions

✅ **Optional: Video Walkthrough**
- 5-7 minute demo video
- Code explanation and live demo
- Technical highlights and benefits

---

## 🎯 Success Criteria

Your completed deliverable should demonstrate:

1. **Technical Excellence**: Clean architecture, best practices, comprehensive testing
2. **Business Value**: Practical solution solving real portfolio management needs
3. **Documentation Quality**: Clear, comprehensive, and professional documentation
4. **Integration Expertise**: Proper API integration with security and error handling
5. **FSC Knowledge**: Effective use of Financial Services Cloud objects and features

**Estimated Time Investment**: 12-16 hours for complete implementation

Good luck with your Wealth360 FSC Assessment! 🚀