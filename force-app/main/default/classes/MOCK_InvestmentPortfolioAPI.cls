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
                createPortfolioData('PORT-001', 'Retirement Portfolio', 1850000.00),
                createPortfolioData('PORT-002', 'Growth Investment Account', 675000.00),
                createPortfolioData('PORT-003', 'Education Savings Fund', 225000.00),
                createPortfolioData('PORT-004', 'Conservative Income Portfolio', 480000.00)
            },
            'holdingsByPortfolio' => new Map<String, Object>{
                'PORT-001' => new List<Object>{
                    createHoldingData('HOLD-001', 'PORT-001', 'Stocks', 'US Large Cap Equity Fund', 650000.00, 35.14),
                    createHoldingData('HOLD-002', 'PORT-001', 'Bonds', 'Government Bond Index', 425000.00, 22.97),
                    createHoldingData('HOLD-003', 'PORT-001', 'International', 'Emerging Markets Fund', 280000.00, 15.14),
                    createHoldingData('HOLD-004', 'PORT-001', 'Real Estate', 'REIT Portfolio', 235000.00, 12.70),
                    createHoldingData('HOLD-005', 'PORT-001', 'Commodities', 'Gold ETF', 185000.00, 10.00),
                    createHoldingData('HOLD-006', 'PORT-001', 'Cash', 'Money Market Fund', 75000.00, 4.05)
                },
                'PORT-002' => new List<Object>{
                    createHoldingData('HOLD-007', 'PORT-002', 'Stocks', 'Technology Growth Fund', 285000.00, 42.22),
                    createHoldingData('HOLD-008', 'PORT-002', 'Stocks', 'Small Cap Value Fund', 195000.00, 28.89),
                    createHoldingData('HOLD-009', 'PORT-002', 'International', 'European Equity Fund', 125000.00, 18.52),
                    createHoldingData('HOLD-010', 'PORT-002', 'Cash', 'High Yield Savings', 70000.00, 10.37)
                },
                'PORT-003' => new List<Object>{
                    createHoldingData('HOLD-011', 'PORT-003', 'Stocks', 'Education Target Date Fund', 135000.00, 60.00),
                    createHoldingData('HOLD-012', 'PORT-003', 'Bonds', 'Corporate Bond Fund', 65000.00, 28.89),
                    createHoldingData('HOLD-013', 'PORT-003', 'Cash', 'Stable Value Fund', 25000.00, 11.11)
                },
                'PORT-004' => new List<Object>{
                    createHoldingData('HOLD-014', 'PORT-004', 'Bonds', 'Treasury Income Fund', 215000.00, 44.79),
                    createHoldingData('HOLD-015', 'PORT-004', 'Dividend', 'Dividend Growth Fund', 165000.00, 34.38),
                    createHoldingData('HOLD-016', 'PORT-004', 'Real Estate', 'Income REIT Fund', 75000.00, 15.63),
                    createHoldingData('HOLD-017', 'PORT-004', 'Cash', 'Certificate of Deposit', 25000.00, 5.21)
                }
            },
            'transactionsByPortfolio' => new Map<String, Object>{
                'PORT-001' => new List<Object>{
                    createTransactionData('TXN-001', 'PORT-001', 'Buy', 25000.00, System.today().addDays(-3), 'Monthly contribution - Technology Fund'),
                    createTransactionData('TXN-002', 'PORT-001', 'Dividend', 1250.00, System.today().addDays(-7), 'Quarterly dividend payment'),
                    createTransactionData('TXN-003', 'PORT-001', 'Rebalance', -15000.00, System.today().addDays(-14), 'Portfolio rebalancing - sold bonds'),
                    createTransactionData('TXN-004', 'PORT-001', 'Rebalance', 15000.00, System.today().addDays(-14), 'Portfolio rebalancing - bought equities'),
                    createTransactionData('TXN-005', 'PORT-001', 'Buy', 30000.00, System.today().addDays(-28), 'Annual bonus investment')
                },
                'PORT-002' => new List<Object>{
                    createTransactionData('TXN-006', 'PORT-002', 'Buy', 15000.00, System.today().addDays(-2), 'Growth fund purchase'),
                    createTransactionData('TXN-007', 'PORT-002', 'Sell', -8500.00, System.today().addDays(-9), 'Partial profit taking'),
                    createTransactionData('TXN-008', 'PORT-002', 'Dividend', 875.00, System.today().addDays(-15), 'Technology dividend'),
                    createTransactionData('TXN-009', 'PORT-002', 'Buy', 12000.00, System.today().addDays(-21), 'Small cap value addition'),
                    createTransactionData('TXN-010', 'PORT-002', 'Buy', 20000.00, System.today().addDays(-35), 'International diversification')
                },
                'PORT-003' => new List<Object>{
                    createTransactionData('TXN-011', 'PORT-003', 'Buy', 5000.00, System.today().addDays(-1), 'Monthly education savings'),
                    createTransactionData('TXN-012', 'PORT-003', 'Buy', 5000.00, System.today().addDays(-32), 'Monthly education savings'),
                    createTransactionData('TXN-013', 'PORT-003', 'Interest', 125.00, System.today().addDays(-30), 'Savings account interest'),
                    createTransactionData('TXN-014', 'PORT-003', 'Buy', 10000.00, System.today().addDays(-45), 'Birthday gift contribution'),
                    createTransactionData('TXN-015', 'PORT-003', 'Buy', 5000.00, System.today().addDays(-63), 'Monthly education savings')
                },
                'PORT-004' => new List<Object>{
                    createTransactionData('TXN-016', 'PORT-004', 'Dividend', 2100.00, System.today().addDays(-5), 'Quarterly income distribution'),
                    createTransactionData('TXN-017', 'PORT-004', 'Interest', 650.00, System.today().addDays(-15), 'Bond coupon payment'),
                    createTransactionData('TXN-018', 'PORT-004', 'Buy', 8000.00, System.today().addDays(-22), 'Additional REIT investment'),
                    createTransactionData('TXN-019', 'PORT-004', 'Dividend', 1950.00, System.today().addDays(-35), 'Monthly dividend income'),
                    createTransactionData('TXN-020', 'PORT-004', 'Reinvest', 1200.00, System.today().addDays(-42), 'Dividend reinvestment')
                }
            }
        };
        return JSON.serialize(response);
    }
    
    private String getCompletePortfolioResponse() {
        Map<String, Object> response = new Map<String, Object>{
            'success' => true,
            'portfolios' => new List<Object>{
                createPortfolioData('PORT-001', 'Retirement Portfolio', 750000.00)
            },
            'holdingsByPortfolio' => new Map<String, Object>{
                'PORT-001' => new List<Object>{
                    new Map<String, Object>{
                        'holdingId' => 'HOLD-001',
                        'portfolio_id' => 'PORT-001',
                        'asset_category' => 'Stocks',
                        'asset_name' => 'US Equities',
                        'market_value' => 350000.00,
                        'quantity' => 1000,
                        'price_per_unit' => 350.00,
                        'last_updated' => '2025-12-03T10:00:00Z'
                    }
                }
            },
            'transactionsByPortfolio' => new Map<String, Object>{
                'PORT-001' => new List<Object>{
                    new Map<String, Object>{
                        'transactionId' => 'TXN-001',
                        'portfolio_id' => 'PORT-001',
                        'transaction_type' => 'Buy',
                        'amount' => 5000.00,
                        'transaction_date' => '2025-11-28',
                        'status' => 'Completed',
                        'description' => 'Stock Purchase'
                    }
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