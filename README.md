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
   git clone https://github.com/YannickT18/Wealth360-FSC-Assessment.git
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
- [Replication Guide](docs/REPLICATION_GUIDE.md)
- [Interview Questions](docs/INTERVIEW_QUESTIONS.md)
- [Git Repository Setup](docs/GIT_REPOSITORY_SETUP.md)

## 🎯 Architecture Highlights

### Service Layer Pattern
```
Controller Layer (CTRL_Wealth360Dashboard)
    ↓
API Service (SRV_InvestmentPortfolioAPI) 
    ↓
Business Logic (SRV_PortfolioUpdate)
    ↓
Data Transfer (WRP_Wealth360Dashboard)
```

### Metadata-Driven Configuration
- Custom Metadata Type: `Wealth360_Field_Mapping__mdt`
- Configurable field mappings without code deployment
- Support for different data types and validation

### Performance Optimization
- **Before**: 3 separate API calls (portfolios, holdings, transactions)
- **After**: 1 comprehensive API call with all data
- **Result**: 60% performance improvement

## 🛠️ Technical Stack

- **Platform**: Salesforce Financial Services Cloud
- **Backend**: Apex (Service Layer Pattern)
- **Frontend**: Lightning Web Components
- **Integration**: Named Credentials + HTTP Callouts
- **Configuration**: Custom Metadata Types
- **Testing**: Apex Test Framework with Mock Services

## 🎯 Business Value

- **Performance**: Faster data synchronization
- **Flexibility**: Administrator-configurable field mappings
- **Maintainability**: Clean architecture with separation of concerns
- **Scalability**: Easy to extend for new object types or API endpoints
- **Security**: Proper field-level security and sharing model implementation

## 👨‍💻 Author

**Yannick Kayombo**
- GitHub: [@YannickT18](https://github.com/YannickT18)
- LinkedIn: [Yannick Kayombo](https://linkedin.com/in/yannick-kayombo)

---

*This project demonstrates enterprise-grade Salesforce development patterns and best practices for Financial Services Cloud implementations.*

