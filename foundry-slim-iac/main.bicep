// =============================================================================
// Foundry Slim — AI Foundry + Observability Only
// =============================================================================
// Deploys a minimal AI Foundry environment with two projects and model deployments.
// No connected resources (Search, Storage, Cosmos, Key Vault, Bing) — only
// Application Insights for observability.
//
// Usage:
//   az deployment group create \
//     --resource-group <team-rg> \
//     --template-file main.bicep \
//     --parameters main.bicepparam
// =============================================================================

targetScope = 'resourceGroup'

// Parameters

@description('Azure region for all resources')
param location string

@description('Short identifier used in all resource names (e.g., aiteam01)')
@maxLength(12)
param projectName string

@description('Short identifier for the second project (e.g., aiteam02)')
@maxLength(12)
param project2Name string

@description('Entra ID group object ID — Account Owners (Azure AI Administrator on the Foundry Resource)')
param accountOwnerGroupObjectId string

@description('Entra ID group object ID — Dev Team for Project 1 (Azure AI Developer)')
param project1DevGroupObjectId string

@description('Entra ID group object ID — Dev Team for Project 2 (Azure AI Developer)')
param project2DevGroupObjectId string

@description('Entra ID group object ID — Subscription Admins (Contributor across entire subscription)')
param subscriptionAdminGroupObjectId string

@description('Environment tag')
@allowed(['dev', 'experimental', 'poc'])
param environmentTag string = 'dev'

@description('Business unit code for cost tagging')
param businessUnit string

@description('Finance allocation code')
param costCenter string

@description('Email of the Foundry Owner for budget alerts')
param ownerEmail string

@description('Monthly budget amount in USD')
param monthlyBudget int = 500

@description('Array of model deployments — each entry: { deploymentName, name, format, version, skuName, capacity }')
param modelDeployments array

// Variables

param deploymentTimestamp string = utcNow('yyyyMMddHHmmss')
var uniqueSuffix = substring(uniqueString(resourceGroup().id), 0, 4)

var resourcePrefix = toLower(businessUnit)
var accountName = toLower('${resourcePrefix}${uniqueSuffix}')
var foundryProjectName = toLower('${projectName}-proj-${uniqueSuffix}')
var foundryProject2Name = toLower('${project2Name}-proj-${uniqueSuffix}')
var budgetStartDate = '${substring(deploymentTimestamp, 0, 4)}-${substring(deploymentTimestamp, 4, 2)}-01'

var tags = {
  BusinessUnit: businessUnit
  AppName: projectName
  Environment: environmentTag
  CostCenter: costCenter
}

resource rgTags 'Microsoft.Resources/tags@2024-03-01' = {
  name: 'default'
  properties: {
    tags: tags
  }
}

// =============================================================================
// STEP 1: AI Foundry Resource + Projects + Model Deployments
// =============================================================================

module aiFoundry 'modules/ai-foundry.bicep' = {
  name: 'deploy-foundry-${uniqueSuffix}'
  params: {
    accountName: accountName
    location: location
    projectName: foundryProjectName
    projectDisplayName: '${projectName} Project'
    projectDescription: '${projectName} — ${environmentTag} environment'
    project2Name: foundryProject2Name
    project2DisplayName: '${project2Name} Project'
    project2Description: '${project2Name} — ${environmentTag} environment'
    modelDeployments: modelDeployments
  }
}

// =============================================================================
// STEP 2: Observability — Log Analytics, App Insights, Foundry Diagnostics
// =============================================================================

module observability 'modules/observability.bicep' = {
  name: 'deploy-observability-${uniqueSuffix}'
  params: {
    namePrefix: businessUnit
    location: location
    aiFoundryName: aiFoundry.outputs.accountName
  }
}

// =============================================================================
// STEP 3: App Insights Foundry Connection
// =============================================================================

module foundryConnection 'modules/foundry-connection.bicep' = {
  name: 'deploy-connection-${uniqueSuffix}'
  params: {
    foundryAccountName: aiFoundry.outputs.accountName
    appInsightsId: observability.outputs.appInsightsId
    appInsightsConnectionString: observability.outputs.appInsightsConnectionString
  }
}

// =============================================================================
// STEP 4: RBAC — Account Owner Group (Azure AI Administrator on Foundry Resource)
// =============================================================================

module rbacAccountOwnerGroup 'modules/rbac-account-owner-group.bicep' = {
  name: 'deploy-rbac-acct-owner-${uniqueSuffix}'
  params: {
    accountOwnerGroupObjectId: accountOwnerGroupObjectId
    foundryAccountName: aiFoundry.outputs.accountName
  }
}

// =============================================================================
// STEP 5: RBAC — Project 1 Dev Group (Azure AI Developer on Project 1)
// =============================================================================

module rbacProject1DevGroup 'modules/rbac-project-dev-group.bicep' = {
  name: 'deploy-rbac-proj1-dev-${uniqueSuffix}'
  params: {
    devGroupObjectId: project1DevGroupObjectId
    foundryAccountName: aiFoundry.outputs.accountName
    foundryProjectName: aiFoundry.outputs.projectName
  }
}

// =============================================================================
// STEP 6: RBAC — Project 2 Dev Group (Azure AI Developer on Project 2)
// =============================================================================

module rbacProject2DevGroup 'modules/rbac-project-dev-group.bicep' = {
  name: 'deploy-rbac-proj2-dev-${uniqueSuffix}'
  params: {
    devGroupObjectId: project2DevGroupObjectId
    foundryAccountName: aiFoundry.outputs.accountName
    foundryProjectName: aiFoundry.outputs.project2Name
  }
}

// =============================================================================
// STEP 7: RBAC — Subscription Admin Group (Contributor at subscription scope)
// =============================================================================

module rbacSubscriptionAdmin 'modules/rbac-subscription-admin.bicep' = {
  name: 'deploy-rbac-sub-admin-${uniqueSuffix}'
  scope: subscription()
  params: {
    subscriptionAdminGroupObjectId: subscriptionAdminGroupObjectId
  }
}

// =============================================================================
// STEP 8: Budget Alert
// =============================================================================

module budget 'modules/budget.bicep' = {
  name: 'deploy-budget-${uniqueSuffix}'
  params: {
    namePrefix: businessUnit
    monthlyBudget: monthlyBudget
    ownerEmail: ownerEmail
    startDate: budgetStartDate
  }
}

// Outputs

output foundryAccountName string = aiFoundry.outputs.accountName
output foundryAccountEndpoint string = aiFoundry.outputs.accountEndpoint
output foundryProject1Name string = aiFoundry.outputs.projectName
output foundryProject2Name string = aiFoundry.outputs.project2Name
output logAnalyticsName string = observability.outputs.logAnalyticsName
output appInsightsName string = observability.outputs.appInsightsName
