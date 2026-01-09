/**
 * @description Service class for integrating with external Investment Portfolio API
 * @author Yannick Kayombo
 * @date 22-11-2025
 */
public with sharing class SRV_InvestmentPortfolioAPI {
    
    private static final String NAMED_CREDENTIAL = 'InvestmentPortfolioAPI';
    private static final Integer MAX_RETRIES = 3;
    private static final Integer INITIAL_RETRY_DELAY = 1000; // milliseconds
    
    /**
     * @description Response wrapper for API calls
     */
    public class APIResponse {
        public Boolean success;
        public String errorMessage;
        public Object data;
        public Integer statusCode;
        
        public APIResponse(Boolean success, Object data, Integer statusCode) {
            this.success = success;
            this.data = data;
            this.statusCode = statusCode;
        }
        
        public APIResponse(Boolean success, String errorMessage, Integer statusCode) {
            this.success = success;
            this.errorMessage = errorMessage;
            this.statusCode = statusCode;
        }
    }
    
    /**
     * @description Wrapper for comprehensive portfolio data from single API call
     */
    public class ComprehensivePortfolioData {
        public List<Map<String, Object>> portfolios;
        public Map<String, List<Map<String, Object>>> holdingsByPortfolio;
        public Map<String, List<Map<String, Object>>> transactionsByPortfolio;
        
        public ComprehensivePortfolioData() {
            this.portfolios = new List<Map<String, Object>>();
            this.holdingsByPortfolio = new Map<String, List<Map<String, Object>>>();
            this.transactionsByPortfolio = new Map<String, List<Map<String, Object>>>();
        }
    }
    
    /**
     * @description Fetch comprehensive portfolio data for an account in a single request
     * @param accountId Salesforce Account ID
     * @param includeHoldings Whether to include holdings data
     * @param includeTransactions Whether to include recent transactions
     * @param transactionDays Number of days for transaction history (default 30)
     * @return APIResponse containing complete portfolio data
     */
    public static APIResponse getComprehensivePortfolioData(Id accountId, Boolean includeHoldings, Boolean includeTransactions, Integer transactionDays) {
        String endpoint = 'callout:' + NAMED_CREDENTIAL + '/api/v1/portfolios/comprehensive?accountId=' + accountId;
        
        // Add query parameters for comprehensive data
        List<String> params = new List<String>();
        if (includeHoldings != null && includeHoldings) {
            params.add('includeHoldings=true');
        }
        if (includeTransactions != null && includeTransactions) {
            params.add('includeTransactions=true');
            if (transactionDays != null && transactionDays > 0) {
                params.add('transactionDays=' + transactionDays);
            }
        }
        
        if (!params.isEmpty()) {
            endpoint += '&' + String.join(params, '&');
        }
        
        return makeCalloutWithRetry(endpoint, 'GET', null);
    }

    /**
     * @description Convenience method to get all data needed for Salesforce sync in one call
     * @param accountId Salesforce Account ID
     * @return ComprehensivePortfolioData containing all portfolio, holdings, and transaction data
     */
    public static ComprehensivePortfolioData getAllPortfolioDataForSync(Id accountId) {
        APIResponse response = getComprehensivePortfolioData(accountId, true, true, 30);
        
        if (response.success && response.data != null) {
            Map<String, Object> responseData = (Map<String, Object>)response.data;
            return parseComprehensiveData(responseData);
        } else {
            System.debug('Failed to fetch comprehensive portfolio data: ' + response.errorMessage);
            return new ComprehensivePortfolioData(); // Return empty data structure
        }
    }
    
    /**
     * @description Make HTTP callout with retry logic
     * @param endpoint Full endpoint URL (including Named Credential)
     * @param method HTTP method (GET, POST, etc.)
     * @param body Request body (null for GET requests)
     * @return APIResponse
     */
    @TestVisible
    private static APIResponse makeCalloutWithRetry(String endpoint, String method, String body) {
        Integer retryCount = 0;
        Integer retryDelay = INITIAL_RETRY_DELAY;
        
        while (retryCount <= MAX_RETRIES) {
            try {
                HttpRequest req = new HttpRequest();
                req.setEndpoint(endpoint);
                req.setMethod(method);
                req.setHeader('Content-Type', 'application/json');
                req.setHeader('Accept', 'application/json');
                req.setTimeout(120000); // 2 minutes
                
                if (body != null && method != 'GET') {
                    req.setBody(body);
                }
                
                Http http = new Http();
                HttpResponse res = http.send(req);
                
                // Handle rate limiting (429)
                if (res.getStatusCode() == 429) {
                    if (retryCount < MAX_RETRIES) {
                        retryCount++;
                        // Exponential backoff
                        Integer delay = retryDelay * (Integer)Math.pow(2, retryCount - 1);
                        // In real implementation, would use Queueable for async retry
                        // For now, log and return error
                        System.debug('Rate limited. Retry attempt ' + retryCount + ' after ' + delay + 'ms');
                        continue;
                    }
                    return new APIResponse(false, 'Rate limit exceeded', 429);
                }
                
                // Handle server errors (5xx) with retry
                if (res.getStatusCode() >= 500 && res.getStatusCode() < 600) {
                    if (retryCount < MAX_RETRIES) {
                        retryCount++;
                        System.debug('Server error. Retry attempt ' + retryCount);
                        continue;
                    }
                    return new APIResponse(false, 'Server error after ' + MAX_RETRIES + ' retries', 
                                         res.getStatusCode());
                }
                
                // Handle success
                if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
                    Map<String, Object> responseData = 
                        (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                    return new APIResponse(true, responseData, res.getStatusCode());
                }
                
                // Handle client errors (4xx) - no retry
                return new APIResponse(false, 'Client error: ' + res.getBody(), res.getStatusCode());
                
            } catch (CalloutException e) {
                if (retryCount < MAX_RETRIES) {
                    retryCount++;
                    System.debug('Callout exception. Retry attempt ' + retryCount + ': ' + e.getMessage());
                    continue;
                }
                return new APIResponse(false, 'Callout failed: ' + e.getMessage(), 500);
            } catch (Exception e) {
                // Don't retry on parsing errors
                return new APIResponse(false, 'Unexpected error: ' + e.getMessage(), 500);
            }
        }
        
        return new APIResponse(false, 'Max retries exceeded', 500);
    }
    
    /**
     * @description Parse comprehensive portfolio data from API response in a single efficient transaction
     * @param responseData Map containing API response data
     * @return ComprehensivePortfolioData wrapper containing all parsed data
     */
    public static ComprehensivePortfolioData parseComprehensiveData(Map<String, Object> responseData) {
        ComprehensivePortfolioData result = new ComprehensivePortfolioData();
        
        // Parse portfolios directly
        if (responseData.containsKey('portfolios')) {
            List<Object> portfolioList = (List<Object>)responseData.get('portfolios');
            for (Object portfolio : portfolioList) {
                result.portfolios.add((Map<String, Object>)portfolio);
            }
        } else if (responseData.containsKey('portfolio')) {
            result.portfolios.add((Map<String, Object>)responseData.get('portfolio'));
        }
        
        // Parse holdings directly if included
        if (responseData.containsKey('allHoldings')) {
            Map<String, Object> holdingsData = (Map<String, Object>)responseData.get('allHoldings');
            
            for (String portfolioId : holdingsData.keySet()) {
                List<Object> holdingList = (List<Object>)holdingsData.get(portfolioId);
                List<Map<String, Object>> holdings = new List<Map<String, Object>>();
                
                for (Object holding : holdingList) {
                    holdings.add((Map<String, Object>)holding);
                }
                result.holdingsByPortfolio.put(portfolioId, holdings);
            }
        }
        
        // Parse transactions directly if included
        if (responseData.containsKey('allTransactions')) {
            Map<String, Object> transactionsData = (Map<String, Object>)responseData.get('allTransactions');
            
            for (String portfolioId : transactionsData.keySet()) {
                List<Object> transactionList = (List<Object>)transactionsData.get(portfolioId);
                List<Map<String, Object>> transactions = new List<Map<String, Object>>();
                
                for (Object txn : transactionList) {
                    transactions.add((Map<String, Object>)txn);
                }
                result.transactionsByPortfolio.put(portfolioId, transactions);
            }
        }
        
        return result;
    }
}