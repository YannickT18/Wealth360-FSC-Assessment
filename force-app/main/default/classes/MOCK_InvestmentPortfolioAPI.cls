/**
 * @description Mock HTTP callout service for external investment portfolio API
 * @author Yannick Kayombo
 * @date 22-11-2025
 */
@isTest
public class MOCK_InvestmentPortfolioAPI implements HttpCalloutMock {
    
    private Integer statusCode;
    private String responseType;
    private Boolean throwInvalidJson;
    
    public MOCK_InvestmentPortfolioAPI() {
        this.statusCode = 200;
        this.responseType = 'portfolios';
        this.throwInvalidJson = false;
    }
    
    public MOCK_InvestmentPortfolioAPI(Integer statusCode, String responseType) {
        this.statusCode = statusCode;
        this.responseType = responseType;
        this.throwInvalidJson = false;
    }
    
    public MOCK_InvestmentPortfolioAPI(Integer statusCode, String responseType, Boolean throwInvalidJson) {
        this.statusCode = statusCode;
        this.responseType = responseType;
        this.throwInvalidJson = throwInvalidJson;
    }
    
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(statusCode);
        
        // Return invalid JSON if requested
        if (throwInvalidJson) {
            res.setBody('INVALID JSON {]');
            return res;
        }
        
        if (statusCode == 200) {
            if (req.getEndpoint().contains('/portfolios?accountId')) {
                // Portfolios request with accountId parameter (comprehensive response)
                res.setBody(getCompletePortfolioResponse());
            } else if (req.getEndpoint().contains('/complete-portfolio')) {
                // Complete portfolio request (new structure)
                res.setBody(getCompletePortfolioResponse());
            } else if (req.getEndpoint().contains('/portfolios/')) {
                // Single portfolio request
                res.setBody(getSinglePortfolioResponse());
            } else if (req.getEndpoint().contains('/portfolios')) {
                // Multiple portfolios (fallback)
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
                createPortfolioData('PORT-201', 'Executive Investment Portfolio', 2450000.00),
                createPortfolioData('PORT-202', 'Tech Startup Fund', 890000.00),
                createPortfolioData('PORT-203', 'Real Estate Investment Trust', 1200000.00),
                createPortfolioData('PORT-204', 'International Diversified Fund', 650000.00)
            },
            'holdingsByPortfolio' => new Map<String, Object>{
                'PORT-201' => new List<Object>{
                    createHoldingData('HOLD-201', 'PORT-201', 'Stocks', 'Microsoft Corporation', 800000.00, 32.65),
                    createHoldingData('HOLD-202', 'PORT-201', 'Stocks', 'Apple Inc', 650000.00, 26.53),
                    createHoldingData('HOLD-203', 'PORT-201', 'Bonds', 'Corporate High Yield', 500000.00, 20.41),
                    createHoldingData('HOLD-204', 'PORT-201', 'International', 'Asian Growth Fund', 300000.00, 12.24),
                    createHoldingData('HOLD-205', 'PORT-201', 'Commodities', 'Silver Futures', 150000.00, 6.12),
                    createHoldingData('HOLD-206', 'PORT-201', 'Cash', 'Premium Money Market', 50000.00, 2.04)
                },
                'PORT-202' => new List<Object>{
                    createHoldingData('HOLD-207', 'PORT-202', 'Stocks', 'NVIDIA Corporation', 350000.00, 39.33),
                    createHoldingData('HOLD-208', 'PORT-202', 'Stocks', 'Tesla Inc', 275000.00, 30.90),
                    createHoldingData('HOLD-209', 'PORT-202', 'Stocks', 'Amazon Web Services ETF', 165000.00, 18.54),
                    createHoldingData('HOLD-210', 'PORT-202', 'Cash', 'Tech Sector Cash Reserve', 100000.00, 11.24)
                },
                'PORT-203' => new List<Object>{
                    createHoldingData('HOLD-211', 'PORT-203', 'Real Estate', 'Commercial Property REIT', 500000.00, 41.67),
                    createHoldingData('HOLD-212', 'PORT-203', 'Real Estate', 'Residential Property Fund', 400000.00, 33.33),
                    createHoldingData('HOLD-213', 'PORT-203', 'Real Estate', 'Industrial REIT', 200000.00, 16.67),
                    createHoldingData('HOLD-214', 'PORT-203', 'Cash', 'Property Investment Cash', 100000.00, 8.33)
                },
                'PORT-204' => new List<Object>{
                    createHoldingData('HOLD-215', 'PORT-204', 'International', 'European Blue Chip Fund', 200000.00, 30.77),
                    createHoldingData('HOLD-216', 'PORT-204', 'International', 'Canadian Resource Fund', 180000.00, 27.69),
                    createHoldingData('HOLD-217', 'PORT-204', 'International', 'Emerging Markets Bond', 150000.00, 23.08),
                    createHoldingData('HOLD-218', 'PORT-204', 'Dividend', 'Global Dividend Aristocrats', 120000.00, 18.46)
                }
            },
            'transactionsByPortfolio' => new Map<String, Object>{
                'PORT-201' => new List<Object>{
                    createTransactionData('TXN-201', 'PORT-201', 'Buy', 45000.00, System.today().addDays(-1), 'Executive bonus allocation'),
                    createTransactionData('TXN-202', 'PORT-201', 'Dividend', 3200.00, System.today().addDays(-5), 'Microsoft quarterly dividend'),
                    createTransactionData('TXN-203', 'PORT-201', 'Sell', -25000.00, System.today().addDays(-12), 'Portfolio optimization'),
                    createTransactionData('TXN-204', 'PORT-201', 'Buy', 80000.00, System.today().addDays(-18), 'Apple stock purchase'),
                    createTransactionData('TXN-205', 'PORT-201', 'Interest', 2150.00, System.today().addDays(-25), 'Bond interest payment')
                },
                'PORT-202' => new List<Object>{
                    createTransactionData('TXN-206', 'PORT-202', 'Buy', 35000.00, System.today().addDays(-2), 'NVIDIA position increase'),
                    createTransactionData('TXN-207', 'PORT-202', 'Sell', -15000.00, System.today().addDays(-8), 'Tesla profit taking'),
                    createTransactionData('TXN-208', 'PORT-202', 'Buy', 50000.00, System.today().addDays(-15), 'AWS ETF initial purchase'),
                    createTransactionData('TXN-209', 'PORT-202', 'Dividend', 750.00, System.today().addDays(-20), 'Technology dividend'),
                    createTransactionData('TXN-210', 'PORT-202', 'Buy', 25000.00, System.today().addDays(-30), 'Tech sector expansion')
                },
                'PORT-203' => new List<Object>{
                    createTransactionData('TXN-211', 'PORT-203', 'Buy', 60000.00, System.today().addDays(-3), 'Commercial REIT expansion'),
                    createTransactionData('TXN-212', 'PORT-203', 'Dividend', 4100.00, System.today().addDays(-7), 'Monthly REIT distribution'),
                    createTransactionData('TXN-213', 'PORT-203', 'Reinvest', 4100.00, System.today().addDays(-7), 'Dividend reinvestment'),
                    createTransactionData('TXN-214', 'PORT-203', 'Buy', 40000.00, System.today().addDays(-14), 'Industrial property fund'),
                    createTransactionData('TXN-215', 'PORT-203', 'Interest', 850.00, System.today().addDays(-28), 'Property loan interest')
                },
                'PORT-204' => new List<Object>{
                    createTransactionData('TXN-216', 'PORT-204', 'Buy', 22000.00, System.today().addDays(-4), 'European fund allocation'),
                    createTransactionData('TXN-217', 'PORT-204', 'Buy', 18000.00, System.today().addDays(-10), 'Canadian resource investment'),
                    createTransactionData('TXN-218', 'PORT-204', 'Dividend', 1800.00, System.today().addDays(-16), 'Global dividend payment'),
                    createTransactionData('TXN-219', 'PORT-204', 'Interest', 925.00, System.today().addDays(-22), 'Emerging markets bond'),
                    createTransactionData('TXN-220', 'PORT-204', 'Rebalance', 15000.00, System.today().addDays(-35), 'International rebalancing')
                }
            }
        };
        return JSON.serialize(response);
    }
    
    private String getCompletePortfolioResponse() {
        return getPortfoliosResponse(); // Use the comprehensive data for complete portfolio response
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
            'portfolioId' => portfolioId,
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
            'holdingId' => holdingId,
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
            'transactionId' => txnId,
            'portfolio_id' => portfolioId,
            'transaction_type' => type,
            'amount' => amount,
            'transaction_date' => txnDate.format(),
            'status' => 'Completed',
            'description' => type + ' transaction for portfolio ' + portfolioId
        };
    }
    
    private Map<String, Object> createTransactionData(String txnId, String portfolioId, 
                                                       String type, Decimal amount, Date txnDate, String description) {
        return new Map<String, Object>{
            'transactionId' => txnId,
            'portfolio_id' => portfolioId,
            'transaction_type' => type,
            'amount' => amount,
            'transaction_date' => txnDate.format(),
            'status' => 'Completed',
            'description' => description
        };
    }
}
