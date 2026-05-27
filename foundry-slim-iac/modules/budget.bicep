// Deploys a budget alert on the resource group with notifications at 80% and 100%.

@description('Name prefix for the budget')
param namePrefix string

@description('Monthly budget amount in USD')
param monthlyBudget int

@description('Email address of the Foundry Owner for budget alerts')
param ownerEmail string

@description('Start date for the budget (first of the current month)')
param startDate string

resource budget 'Microsoft.Consumption/budgets@2023-11-01' = {
  name: '${namePrefix}-budget'
  properties: {
    category: 'Cost'
    amount: monthlyBudget
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: startDate
    }
    notifications: {
      atEightyPercent: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 80
        contactEmails: [ownerEmail]
        thresholdType: 'Actual'
      }
      atOneHundredPercent: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 100
        contactEmails: [ownerEmail]
        thresholdType: 'Actual'
      }
    }
  }
}
