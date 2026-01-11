/**
 * @description Mock HTTP callout service for external investment portfolio API
 * @author Yannick Kayombo
 * @date 22-11-2025
 */
@isTest
public class Mock_InvestmentPortfolioAPI implements HttpCalloutMock {
    
    private Integer statusCode;
    private String responseType;
    
    public Mock_InvestmentPortfolioAPI() {
        this.statusCode = 200;
        this.responseType = 'portfolios';
    }
    
    public Mock_InvestmentPortfolioAPI(Integer statusCode, String responseType) {
        this.statusCode = statusCode;
        this.responseType = responseType;
    }
    
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(statusCode);
        
        if (statusCode == 200) {
            if (req.getEndpoint().contains('/portfolios/')) {
                // Single portfolio request
                res.setBody(getSinglePortfolioResponse());
            } else if (req.getEndpoint().contains('/portfolios')) {
                // Multiple portfolios
                res.setBody(getPortfoliosResponse());
            } else if (req.getEndpoint().contains('/holdings')) {
                res.setBody(getHoldingsResponse());
            } else if (req.getEndpoint().contains('/transactions')) {
                res.setBody(getTransactionsResponse());
            }
        } else if (statusCode == 429) {
            res.setBody('{"error": "Rate limit exceeded", "retryAfter": 60}');
        } else if (statusCode >= 500) {
            res.setBody('{"error": "Internal server error"}');
        } else {
            res.setBody('{"error": "Bad request"}');
        }
        
        return res;
    }
    
    private String getPortfoliosResponse() {
        Map<String, Object> response = new Map<String, Object>{
            'success' => true,
            'portfolios' => new List<Object>{
                createPortfolioData('PORT-001', 'Retirement Account', 750000.00),
                createPortfolioData('PORT-002', 'Investment Account', 450000.00),
                createPortfolioData('PORT-003', 'Education Savings', 125000.00)
            },
            'holdingsByPortfolio' => new Map<String, Object>{
                'PORT-001' => new List<Object>{
                    createHoldingData('HOLD-001', 'PORT-001', 'Stocks', 'US Equities', 350000.00, 46.67),
                    createHoldingData('HOLD-002', 'PORT-001', 'Bonds', 'US Treasury Bonds', 225000.00, 30.00)
                },
                'PORT-002' => new List<Object>{
                    createHoldingData('HOLD-003', 'PORT-002', 'Cash', 'Money Market', 100000.00, 22.22),
                    createHoldingData('HOLD-004', 'PORT-002', 'Stocks', 'International Equities', 350000.00, 77.78)
                }
            },
            'transactionsByPortfolio' => new Map<String, Object>{
                'PORT-001' => new List<Object>{
                    createTransactionData('TXN-001', 'PORT-001', 'Buy', 5000.00, System.today().addDays(-5)),
                    createTransactionData('TXN-002', 'PORT-001', 'Sell', -3000.00, System.today().addDays(-10))
                },
                'PORT-002' => new List<Object>{
                    createTransactionData('TXN-003', 'PORT-002', 'Dividend', 500.00, System.today().addDays(-15)),
                    createTransactionData('TXN-004', 'PORT-002', 'Buy', 10000.00, System.today().addDays(-20))
                }
            }
        };
        return JSON.serialize(response);
    }
    
    private String getSinglePortfolioResponse() {
        Map<String, Object> response = new Map<String, Object>{
            'success' => true,
            'portfolio' => createPortfolioData('PORT-001', 'Retirement Account', 750000.00)
        };
        return JSON.serialize(response);
    }
    
    private Map<String, Object> createPortfolioData(String portfolioId, String name, Decimal totalValue) {
        return new Map<String, Object>{
            'id' => portfolioId,
            'name' => name,
            'total_value' => totalValue,
            'currency' => 'USD',
            'lastUpdated' => System.now().format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''),
            'type' => 'Investment',
            'status' => 'Active'
        };
    }
    
    private String getHoldingsResponse() {
        Map<String, Object> response = new Map<String, Object>{
            'success' => true,
            'holdings' => new List<Object>{
                createHoldingData('HOLD-001', 'PORT-001', 'Stocks', 'US Equities', 350000.00, 46.67),
                createHoldingData('HOLD-002', 'PORT-001', 'Bonds', 'US Treasury Bonds', 225000.00, 30.00),
                createHoldingData('HOLD-003', 'PORT-001', 'Cash', 'Money Market', 100000.00, 13.33),
                createHoldingData('HOLD-004', 'PORT-001', 'Stocks', 'International Equities', 75000.00, 10.00)
            }
        };
        return JSON.serialize(response);
    }
    
    private Map<String, Object> createHoldingData(String holdingId, String portfolioId, 
                                                   String assetCategory, String assetName, 
                                                   Decimal value, Decimal percentage) {
        return new Map<String, Object>{
            'id' => holdingId,
            'portfolio_id' => portfolioId,
            'asset_category' => assetCategory,
            'asset_name' => assetName,
            'market_value' => value,
            'percentage' => percentage,
            'quantity' => 1000,
            'price_per_unit' => value / 1000,
            'last_updated' => System.now().format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'')
        };
    }
    
    private String getTransactionsResponse() {
        Map<String, Object> response = new Map<String, Object>{
            'success' => true,
            'transactions' => new List<Object>{
                createTransactionData('TXN-001', 'PORT-001', 'Buy', 5000.00, System.today().addDays(-5)),
                createTransactionData('TXN-002', 'PORT-001', 'Sell', -3000.00, System.today().addDays(-10)),
                createTransactionData('TXN-003', 'PORT-001', 'Dividend', 500.00, System.today().addDays(-15)),
                createTransactionData('TXN-004', 'PORT-001', 'Buy', 10000.00, System.today().addDays(-20))
            }
        };
        return JSON.serialize(response);
    }
    
    private Map<String, Object> createTransactionData(String txnId, String portfolioId, 
                                                       String type, Decimal amount, Date txnDate) {
        return new Map<String, Object>{
            'id' => txnId,
            'portfolio_id' => portfolioId,
            'transaction_type' => type,
            'amount' => amount,
            'transaction_date' => txnDate.format(),
            'status' => 'Completed',
            'description' => type + ' transaction for portfolio ' + portfolioId
        };
    }
}