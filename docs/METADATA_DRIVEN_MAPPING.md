# Metadata-Driven Field Mapping

## Overview

The Wealth360 FSC Assessment now supports **metadata-driven field mapping** using Custom Metadata Types. This approach eliminates hardcoded field mappings in Apex code and provides administrators with the flexibility to configure field mappings without code deployment.

## Benefits

✅ **Configurable** - Admins can modify field mappings without code changes  
✅ **Maintainable** - Centralized mapping configuration  
✅ **Scalable** - Easy to add new fields or objects  
✅ **Type-Safe** - Automatic data type conversion  
✅ **Default Values** - Support for fallback values when API data is missing  
✅ **Performance** - Cached metadata queries for optimal performance

## Custom Metadata Type: Wealth360_Field_Mapping__mdt

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `Object_Type__c` | Picklist | Object type (Portfolio, Holding, Transaction) |
| `API_Field_Name__c` | Text | Field name from external API response |
| `Salesforce_Field_Name__c` | Text | Target Salesforce field API name |
| `Data_Type__c` | Picklist | Data type for conversion (String, Decimal, Date, DateTime, Boolean) |
| `Default_Value__c` | Text | Default value if API field is null/missing |
| `Is_Active__c` | Checkbox | Whether this mapping is active |

## Sample Mappings

### Portfolio Mappings
- `portfolioId` → `ExternalPortfolioId__c` (String)
- `name` → `Name` (String)  
- `totalValue` → `TotalAssetValue__c` (Decimal)
- `type` → `FinServ__FinancialAccountType__c` (String, Default: "Investment")

### Holding Mappings
- `holdingId` → `ExternalHoldingId__c` (String)
- `currentValue` → `FinServ__MarketValue__c` (Decimal)

### Transaction Mappings  
- `transactionId` → `ExternalTransactionId__c` (String)
- `amount` → `FinServ__Amount__c` (Decimal)

## How It Works

1. **UTIL_FieldMapping** class queries all active mappings at startup
2. **mapApiDataToSalesforceRecord()** method applies mappings using metadata configuration
3. **Type conversion** happens automatically based on Data_Type__c field
4. **Default values** are applied when API data is missing
5. **Cache optimization** ensures metadata is only queried once per transaction

## Usage in Code

### Before (Hardcoded)
```apex
fa.ExternalPortfolioId__c = (String)portfolioData.get('portfolioId');
fa.Name = (String)portfolioData.get('name');
fa.FinServ__FinancialAccountType__c = 'Investment';
fa.TotalAssetValue__c = (Decimal)portfolioData.get('totalValue');
```

### After (Metadata-Driven)
```apex
fa = (FinServ__FinancialAccount__c)UTIL_FieldMapping.mapApiDataToSalesforceRecord('Portfolio', portfolioData, fa);
```

## Administration

### Adding New Field Mappings

1. Navigate to **Setup** → **Custom Metadata Types** → **Wealth360 Field Mapping**
2. Click **Manage Records** → **New**
3. Fill in the mapping details:
   - **Label**: Descriptive name for the mapping
   - **Object Type**: Portfolio, Holding, or Transaction
   - **API Field Name**: Exact field name from API response
   - **Salesforce Field Name**: Target field API name
   - **Data Type**: Appropriate type for conversion
   - **Default Value**: Optional fallback value
   - **Is Active**: Check to enable the mapping

### Modifying Existing Mappings

1. Find the mapping record in Custom Metadata
2. Click **Edit** next to the record
3. Update field values as needed
4. Changes take effect immediately (no deployment needed)

### Deactivating Mappings

1. Find the mapping record
2. Uncheck **Is Active**
3. The field will no longer be mapped during sync

## Error Handling

- **Type Conversion Errors**: Logs warning and uses default value
- **Missing Object Types**: Throws `InvalidObjectTypeException`
- **Invalid Field Names**: Salesforce will throw DML exception with details

## Performance Considerations

- Mappings are **cached in memory** after first query
- Cache is **transaction-scoped** (cleared between transactions)
- **Bulk operations** use the same cached mappings
- Metadata queries happen **once per transaction** regardless of record count

## Future Enhancements

- **Conditional Mappings**: Apply mappings based on conditions
- **Field Transformation**: Custom logic for complex field conversions
- **Validation Rules**: Metadata-driven validation before DML
- **Audit Trail**: Track when mappings were last used/modified

## Migration Guide

Existing installations can gradually migrate to metadata-driven approach:

1. Deploy the new Custom Metadata Type and utility class
2. Create mapping records for current hardcoded mappings
3. Update controller methods to use `UTIL_FieldMapping`
4. Test thoroughly in sandbox
5. Deploy to production
6. Remove old hardcoded mapping logic

This approach provides maximum flexibility while maintaining backward compatibility during the transition period.