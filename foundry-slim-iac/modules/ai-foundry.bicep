// Deploys the Azure AI Foundry Resource (AIServices account) with nested Projects
// and model deployments.
// API version aligned with official Microsoft Foundry quickstart samples.

@description('Name of the AI Foundry account')
param accountName string

@description('Azure region for all resources')
param location string

@description('Name of the first project under the Foundry resource')
param projectName string

@description('Display name shown in the Foundry portal')
param projectDisplayName string

@description('Description of the first project')
param projectDescription string

@description('Name of the second project under the Foundry resource')
param project2Name string

@description('Display name for the second project')
param project2DisplayName string

@description('Description of the second project')
param project2Description string

@description('Array of model deployments to create')
param modelDeployments array

// AI Foundry Resource (CognitiveServices account with AIServices kind)
resource account 'Microsoft.CognitiveServices/accounts@2025-06-01' = {
  name: accountName
  location: location
  sku: {
    name: 'S0'
  }
  kind: 'AIServices'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    allowProjectManagement: true
    customSubDomainName: accountName
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: true
    networkAcls: {
      defaultAction: 'Allow'
      virtualNetworkRules: []
      ipRules: []
    }
  }
}

// Project 1
resource project 'Microsoft.CognitiveServices/accounts/projects@2025-06-01' = {
  parent: account
  name: projectName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    description: projectDescription
    displayName: projectDisplayName
  }
}

// Project 2
resource project2 'Microsoft.CognitiveServices/accounts/projects@2025-06-01' = {
  parent: account
  name: project2Name
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    description: project2Description
    displayName: project2DisplayName
  }
}

// Model deployments — deployed sequentially to avoid ARM conflicts on parent resource
@batchSize(1)
resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = [
  for model in modelDeployments: {
    parent: account
    name: model.deploymentName
    sku: {
      capacity: model.capacity
      name: model.skuName
    }
    properties: {
      model: {
        name: model.name
        format: model.format
        version: model.version
      }
    }
  }
]

output accountName string = account.name
output accountId string = account.id
output accountEndpoint string = account.properties.endpoint
output accountPrincipalId string = account.identity.principalId
output projectName string = project.name
output projectId string = project.id
output projectPrincipalId string = project.identity.principalId
output project2Name string = project2.name
output project2Id string = project2.id
output project2PrincipalId string = project2.identity.principalId
