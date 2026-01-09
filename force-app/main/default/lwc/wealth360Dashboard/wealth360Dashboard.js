import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getTotalInvestmentValue from '@salesforce/apex/CTRL_Wealth360Dashboard.getTotalInvestmentValue';
import getAssetAllocation from '@salesforce/apex/CTRL_Wealth360Dashboard.getAssetAllocation';
import getRecentTransactions from '@salesforce/apex/CTRL_Wealth360Dashboard.getRecentTransactions';
import getPortfolioSummary from '@salesforce/apex/CTRL_Wealth360Dashboard.getPortfolioSummary';
import syncPortfolioData from '@salesforce/apex/CTRL_Wealth360Dashboard.syncPortfolioData';

const TRANSACTION_COLUMNS = [
    { label: 'Transaction', fieldName: 'name', type: 'text' },
    { label: 'Type', fieldName: 'type', type: 'text' },
    { 
        label: 'Amount', 
        fieldName: 'amount', 
        type: 'currency',
        typeAttributes: { currencyCode: 'ZAR', step: '0.01' }
    },
    { label: 'Date', fieldName: 'transactionDate', type: 'date' },
    { label: 'Status', fieldName: 'status', type: 'text' },
    { label: 'Account', fieldName: 'accountName', type: 'text' }
];

export default class Wealth360Dashboard extends LightningElement {
    @api recordId; // Account or Household ID
    @track isLoading = false;
    @track error;
    
    // Transaction data
    transactionColumns = TRANSACTION_COLUMNS;
    wiredTransactions;
    
    // Portfolio summary
    wiredSummary;
    portfolioCount = 0;
    holdingsCount = 0;
    
    // Asset allocation chart data
    wiredAssetAllocation;
    
    /**
     * Apply colors to legend items after rendering
     */
    renderedCallback() {
        // Apply background colors to legend items
        const legendColors = this.template.querySelectorAll('.legend-color');
        legendColors.forEach(colorBox => {
            const color = colorBox.dataset.color;
            if (color) {
                colorBox.style.backgroundColor = color;
            }
        });
    }
    
    /**
     * Wire total investment value
     */
    @wire(getTotalInvestmentValue, { accountId: '$recordId' })
    totalInvestmentValue;
    
    /**
     * Wire portfolio summary
     */
    @wire(getPortfolioSummary, { accountId: '$recordId' })
    wiredPortfolioSummary(result) {
        this.wiredSummary = result;
        if (result.data) {
            this.portfolioCount = result.data.portfolioCount;
            this.holdingsCount = result.data.holdingsCount;
            this.error = undefined;
        } else if (result.error) {
            this.error = this.reduceErrors(result.error);
            this.portfolioCount = 0;
            this.holdingsCount = 0;
        }
    }
    
    /**
     * Wire asset allocation data
     */
    @wire(getAssetAllocation, { accountId: '$recordId' })
    wiredAssetAllocationData(result) {
        this.wiredAssetAllocation = result;
        if (result.error) {
            this.error = this.reduceErrors(result.error);
        }
    }
    
    /**
     * Wire recent transactions
     */
    @wire(getRecentTransactions, { accountId: '$recordId', limitCount: 10 })
    wiredTransactionData(result) {
        this.wiredTransactions = result;
        if (result.error) {
            this.error = this.reduceErrors(result.error);
        }
    }
    
    /**
     * Get formatted total investment value
     */
    get formattedTotalValue() {
        if (this.totalInvestmentValue.data !== undefined && this.totalInvestmentValue.data !== null) {
            return new Intl.NumberFormat('en-ZA', {
                style: 'currency',
                currency: 'ZAR',
                minimumFractionDigits: 2
            }).format(this.totalInvestmentValue.data);
        }
        return 'R 0.00';
    }
    
    /**
     * Check if total value has loaded
     */
    get hasTotalValue() {
        return this.totalInvestmentValue.data !== undefined;
    }
    
    /**
     * Get allocation data for donut chart visualization
     */
    get allocationData() {
        if (!this.wiredAssetAllocation.data || this.wiredAssetAllocation.data.length === 0) {
            return [];
        }
        
        const colors = ['#1589EE', '#4FCA62', '#FFB75D', '#E83C6C', '#9D75CB', '#54698D'];
        const circumference = 2 * Math.PI * 80; // radius = 80
        let cumulativePercentage = 0;
        
        return this.wiredAssetAllocation.data.map((item, index) => {
            const percentage = item.percentage;
            const segmentLength = (percentage / 100) * circumference;
            const offset = -((cumulativePercentage / 100) * circumference);
            
            cumulativePercentage += percentage;
            
            return {
                category: item.category,
                percentage: percentage.toFixed(2),
                color: colors[index % colors.length],
                formattedValue: new Intl.NumberFormat('en-ZA', {
                    style: 'currency',
                    currency: 'ZAR'
                }).format(item.value),
                dashArray: `${segmentLength} ${circumference}`,
                dashOffset: offset
            };
        });
    }
    
    /**
     * Check if chart data is available
     */
    get hasChartData() {
        return this.allocationData.length > 0;
    }
    
    /**
     * Get transaction data for datatable
     */
    get transactionData() {
        return this.wiredTransactions.data || [];
    }
    
    /**
     * Check if there are transactions
     */
    get hasTransactions() {
        return this.transactionData.length > 0;
    }
    
    /**
     * Handle sync button click
     */
    handleSync() {
        this.isLoading = true;
        syncPortfolioData({ accountId: this.recordId })
            .then(result => {
                this.showToast(
                    'Success',
                    'Portfolio data synced successfully!',
                    'success'
                );
                // Refresh data immediately
                this.refreshAllData();
            })
            .catch(error => {
                this.error = this.reduceErrors(error);
                this.showToast(
                    'Error',
                    'Failed to sync portfolio data: ' + this.error,
                    'error'
                );
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
    
    /**
     * Refresh all wired data
     */
    refreshAllData() {
        return Promise.all([
            refreshApex(this.wiredSummary),
            refreshApex(this.wiredAssetAllocation),
            refreshApex(this.wiredTransactions),
            refreshApex(this.totalInvestmentValue)
        ]);
    }
    
    /**
     * Show toast notification
     */
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
    
    /**
     * Reduce errors to user-friendly message
     */
    reduceErrors(error) {
        if (!error) {
            return 'Unknown error';
        }
        if (Array.isArray(error.body)) {
            return error.body.map(e => e.message).join(', ');
        } else if (typeof error.body === 'object' && error.body !== null) {
            if (error.body.message) {
                return error.body.message;
            }
            if (error.body.pageErrors && error.body.pageErrors.length > 0) {
                return error.body.pageErrors.map(e => e.message).join(', ');
            }
            if (error.body.fieldErrors) {
                const fieldErrors = Object.values(error.body.fieldErrors);
                return fieldErrors.map(errorArray => 
                    errorArray.map(e => e.message).join(', ')
                ).join(', ');
            }
        } else if (typeof error.body === 'string') {
            return error.body;
        } else if (typeof error.message === 'string') {
            return error.message;
        }
        return JSON.stringify(error);
    }
}
