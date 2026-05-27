// Registers the Application Insights connection on the Foundry account.
// App Insights connections only support ApiKey auth type with the connection string.

@description('Name of the AI Foundry account')
param foundryAccountName string

@description('Resource ID of the Application Insights instance')
param appInsightsId string

@secure()
@description('Connection string of the Application Insights instance')
param appInsightsConnectionString string

resource foundryAccount 'Microsoft.CognitiveServices/accounts@2025-06-01' existing = {
  name: foundryAccountName
}

resource appInsightsConnection 'Microsoft.CognitiveServices/accounts/connections@2025-06-01' = {
  name: '${foundryAccountName}-appinsights'
  parent: foundryAccount
  properties: {
    category: 'AppInsights'
    target: appInsightsId
    authType: 'ApiKey'
    isSharedToAll: true
    credentials: {
      key: appInsightsConnectionString
    }
    metadata: {
      ApiType: 'Azure'
      ResourceId: appInsightsId
    }
  }
}
