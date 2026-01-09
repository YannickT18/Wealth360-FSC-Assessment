# Git Repository Setup Guide for Wealth360 FSC Assessment

Complete step-by-step instructions to create a Git repository with all project files.

## 🔧 Prerequisites

- Git installed on your machine
- GitHub account (or GitLab/Bitbucket)
- Terminal/Command Prompt access

---

## 📁 Step 1: Create Project Directory Structure

```bash
# Create main project folder
mkdir Wealth360-FSC-Assessment
cd Wealth360-FSC-Assessment

# Create all required directories
mkdir -p force-app/main/default/classes
mkdir -p force-app/main/default/lwc/wealth360Dashboard
mkdir -p force-app/main/default/objects/FinServ__FinancialAccount__c/fields
mkdir -p force-app/main/default/objects/FinServ__FinancialHolding__c/fields
mkdir -p force-app/main/default/objects/FinServ__FinancialAccountTransaction__c/fields
mkdir -p force-app/main/default/objects/Wealth360_Field_Mapping__mdt/fields
mkdir -p force-app/main/default/customMetadata
mkdir -p config
mkdir -p manifest
mkdir -p docs
mkdir -p postman
mkdir -p scripts/apex

# Verify structure
tree /f
```

---

## 📄 Step 2: Create Core Project Files

### 2.1 Create sfdx-project.json
```bash
# Create the main SFDX project configuration file
cat > sfdx-project.json << 'EOF'
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
EOF
```

### 2.2 Create package.json
```bash
cat > package.json << 'EOF'
{
  "name": "wealth360-fsc-assessment",
  "version": "1.0.0",
  "description": "Financial Services Cloud Investment Portfolio Management Solution",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1",
    "deploy": "sf project deploy start --source-dir force-app",
    "validate": "sf project deploy validate --source-dir force-app"
  },
  "keywords": ["salesforce", "fsc", "investment", "portfolio"],
  "author": "Your Name",
  "license": "MIT"
}
EOF
```

### 2.3 Create project-scratch-def.json
```bash
cat > config/project-scratch-def.json << 'EOF'
{
  "orgName": "Wealth360 FSC Assessment",
  "edition": "Developer",
  "features": ["FinancialServicesCloud", "PersonAccounts", "API"],
  "settings": {
    "lightningExperienceSettings": {
      "enableS1DesktopEnabled": true
    },
    "mobileSettings": {
      "enableS1EncryptedStoragePref2": false
    }
  }
}
EOF
```

### 2.4 Create package.xml
```bash
cat > manifest/package.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>*</members>
        <name>ApexClass</name>
    </types>
    <types>
        <members>*</members>
        <name>LightningComponentBundle</name>
    </types>
    <types>
        <members>*</members>
        <name>CustomObject</name>
    </types>
    <types>
        <members>*</members>
        <name>CustomField</name>
    </types>
    <types>
        <members>*</members>
        <name>CustomMetadata</name>
    </types>
    <version>60.0</version>
</Package>
EOF
```

---

## 💻 Step 3: Add All Apex Classes

### 3.1 Service Layer Classes
```bash
# Create SRV_InvestmentPortfolioAPI.cls
cat > force-app/main/default/classes/SRV_InvestmentPortfolioAPI.cls << 'EOF'
/**
 * @description API integration service for Investment Portfolio external API
 * @author Wealth360 Team
 * @date 2026
 */
public with sharing class SRV_InvestmentPortfolioAPI {
    
    private static final String NAMED_CREDENTIAL = 'callout:Wealth360_Investment_API';
    private static final String COMPREHENSIVE_ENDPOINT = '/api/v1/portfolios/comprehensive';
    
    public static ComprehensivePortfolioData getAllPortfolioDataForSync(Id accountId) {
        HttpRequest request = buildHttpRequest(accountId);
        HttpResponse response = executeRequest(request);
        return parseComprehensiveResponse(response);
    }
    
    private static HttpRequest buildHttpRequest(Id accountId) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(NAMED_CREDENTIAL + COMPREHENSIVE_ENDPOINT + '?accountId=' + accountId);
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json');
        request.setTimeout(60000);
        return request;
    }
    
    private static HttpResponse executeRequest(HttpRequest request) {
        Http http = new Http();
        HttpResponse response = http.send(request);
        
        if (response.getStatusCode() != 200) {
            throw new CalloutException('API Error: ' + response.getStatus());
        }
        return response;
    }
    
    private static ComprehensivePortfolioData parseComprehensiveResponse(HttpResponse response) {
        return (ComprehensivePortfolioData) JSON.deserialize(
            response.getBody(), ComprehensivePortfolioData.class
        );
    }
    
    public class ComprehensivePortfolioData {
        public Boolean success;
        public List<PortfolioData> portfolios;
        
        public ComprehensivePortfolioData() {
            this.portfolios = new List<PortfolioData>();
        }
    }
    
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
EOF

# Create metadata file
cat > force-app/main/default/classes/SRV_InvestmentPortfolioAPI.cls-meta.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>60.0</apiVersion>
    <status>Active</status>
</ApexClass>
EOF
```

### 3.2 Add All Other Classes
```bash
# Add commands for each class file (SRV_PortfolioUpdate, CTRL_Wealth360Dashboard, etc.)
# ... (continue with all other class files following the same pattern)
```

---

## ⚡ Step 4: Add Lightning Web Component

```bash
# Create LWC files
cat > force-app/main/default/lwc/wealth360Dashboard/wealth360Dashboard.js << 'EOF'
import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

import getTotalInvestmentValue from '@salesforce/apex/CTRL_Wealth360Dashboard.getTotalInvestmentValue';
import syncPortfolioData from '@salesforce/apex/CTRL_Wealth360Dashboard.syncPortfolioData';

export default class Wealth360Dashboard extends LightningElement {
    @api recordId;
    @track totalValue = 0;
    @track isLoading = false;
    
    @wire(getTotalInvestmentValue, { accountId: '$recordId' })
    wiredTotalValue(result) {
        this.wiredTotalValueResult = result;
        if (result.data) {
            this.totalValue = result.data;
        }
    }
    
    handleSyncPortfolio() {
        this.isLoading = true;
        
        syncPortfolioData({ accountId: this.recordId })
            .then(result => {
                if (result === 'SUCCESS') {
                    this.showToast('Success', 'Portfolio data synced successfully', 'success');
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
EOF

# Add other LWC files (HTML, CSS, meta.xml)
# ... (continue with all LWC files)
```

---

## 📚 Step 5: Add Documentation

```bash
# Create main README
cat > README.md << 'EOF'
# Wealth360 Financial Services Cloud Assessment

A comprehensive Salesforce Financial Services Cloud solution for investment portfolio management with external API integration.

## 🏗️ Architecture

- **Service Layer**: Separated API integration and business logic
- **Metadata-Driven**: Configurable field mappings via Custom Metadata
- **Performance Optimized**: Single API call instead of multiple requests
- **Type Safe**: Wrapper classes for clean data contracts

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

## 📖 Documentation

See `docs/` folder for detailed guides:
- [API Integration Guide](docs/API_INTEGRATION_COMPLETE_GUIDE.md)
- [Technical Design](docs/TECHNICAL_DESIGN.md)
- [Replication Guide](docs/REPLICATION_GUIDE.md)
- [Interview Questions](docs/INTERVIEW_QUESTIONS.md)

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
EOF
```

---

## 🔄 Step 6: Initialize Git Repository

```bash
# Initialize Git repository
git init

# Create .gitignore file
cat > .gitignore << 'EOF'
# Salesforce specific
.sf/
.sfdx/
.vscode/settings.json
node_modules/
npm-debug.log*
.nyc_output/
coverage/

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# IDE files
*.log
*.tmp
.idea/
*.swp
*.swo
*~

# Temporary files
*.tmp
*.temp
EOF

# Add all files to staging
git add .

# Make initial commit
git commit -m "Initial commit: Wealth360 FSC Assessment

- Complete SFDX project structure
- Service layer architecture (API integration + business logic)
- Lightning Web Component dashboard
- Custom metadata for field mapping configuration
- Comprehensive test coverage with mocks
- Postman API collection for testing
- Complete documentation package"
```

---

## 🌐 Step 7: Create GitHub Repository

### Option A: Using GitHub CLI (if installed)
```bash
# Create repository on GitHub
gh repo create Wealth360-FSC-Assessment --public --description "Salesforce Financial Services Cloud investment portfolio management solution"

# Push to GitHub
git push -u origin main
```

### Option B: Using GitHub Web Interface

1. **Go to GitHub.com** and sign in
2. **Click "New repository"** button
3. **Fill in repository details:**
   - Repository name: `Wealth360-FSC-Assessment`
   - Description: `Salesforce Financial Services Cloud investment portfolio management solution`
   - Choose Public or Private
   - Don't initialize with README (we already have one)

4. **Copy the repository URL** (e.g., `https://github.com/yourusername/Wealth360-FSC-Assessment.git`)

5. **Add remote and push:**
```bash
git remote add origin https://github.com/yourusername/Wealth360-FSC-Assessment.git
git branch -M main
git push -u origin main
```

---

## 📋 Step 8: Verify Repository Setup

```bash
# Check git status
git status

# View commit history
git log --oneline

# Check remote connection
git remote -v

# Verify all files are tracked
git ls-files
```

Expected output should show all your project files are tracked and committed.

---

## 🏷️ Step 9: Create Release/Tag (Optional)

```bash
# Create a release tag
git tag -a v1.0.0 -m "Wealth360 FSC Assessment v1.0.0 - Complete deliverable package"

# Push tag to GitHub
git push origin v1.0.0
```

---

## 📦 Step 10: Create Submission Package

### For ZIP File Submission
```bash
# Create clean ZIP file excluding git files
zip -r Wealth360-FSC-Assessment-v1.0.0.zip . -x "*.git*" "node_modules/*" ".sf/*" ".sfdx/*"
```

### For Repository Link Submission
Your repository URL will be:
```
https://github.com/yourusername/Wealth360-FSC-Assessment
```

---

## ✅ Final Checklist

After completing all steps, verify your repository contains:

### 📁 **Project Structure**
```
Wealth360-FSC-Assessment/
├── README.md
├── sfdx-project.json
├── package.json
├── .gitignore
├── force-app/main/default/
│   ├── classes/                     # All Apex classes with metadata
│   ├── lwc/wealth360Dashboard/      # Complete LWC component
│   ├── objects/                     # Custom fields and metadata types
│   └── customMetadata/              # Field mapping configuration
├── docs/                           # Complete documentation
├── postman/                        # API collection
├── config/                         # Scratch org definition
└── manifest/                       # Package.xml
```

### 🔧 **Git Repository**
✅ All files committed and pushed to GitHub  
✅ Clear commit history with meaningful messages  
✅ .gitignore properly configured  
✅ README.md with project overview  
✅ Optional: Release tag created  

### 📋 **Deliverables Complete**
✅ Full SFDX project with all metadata  
✅ Apex classes/triggers with comprehensive tests  
✅ Lightning Web Component  
✅ Custom objects and field definitions  
✅ Postman collection for API testing  
✅ Complete documentation package  
✅ Professional README and project description  

**🎯 Result**: Professional Git repository ready for submission with all Wealth360 FSC Assessment deliverables!

---

## 🛠️ Troubleshooting

### Common Issues:

**Git not initialized properly**
```bash
rm -rf .git
git init
git add .
git commit -m "Initial commit"
```

**GitHub authentication issues**
```bash
# Configure Git credentials
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Use personal access token for HTTPS
git remote set-url origin https://yourusername:your_token@github.com/yourusername/Wealth360-FSC-Assessment.git
```

**Large files or performance issues**
```bash
# Check repository size
du -sh .git

# Remove large files from history if needed
git filter-branch --force --index-filter 'git rm --cached --ignore-unmatch path/to/large/file' --prune-empty --tag-name-filter cat -- --all
```

Your Git repository is now ready with all Wealth360 FSC Assessment deliverables! 🚀