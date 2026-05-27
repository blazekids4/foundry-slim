// Assigns Azure AI Developer on a specific Foundry project for a dev team group.
// No connected-service roles — this is a Foundry-only deployment.

@description('Object ID of the Entra ID group for the dev team')
param devGroupObjectId string

@description('Name of the AI Foundry account')
param foundryAccountName string

@description('Name of the AI Foundry project this group has access to')
param foundryProjectName string

var azureAiDeveloperRoleId = '64702f94-c441-49e6-a78b-ef80e0188fee'

resource foundryAccount 'Microsoft.CognitiveServices/accounts@2025-06-01' existing = {
  name: foundryAccountName
}

resource foundryProject 'Microsoft.CognitiveServices/accounts/projects@2025-06-01' existing = {
  name: foundryProjectName
  parent: foundryAccount
}

resource devGroupProjectRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: foundryProject
  name: guid(devGroupObjectId, azureAiDeveloperRoleId, foundryProject.id)
  properties: {
    principalId: devGroupObjectId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', azureAiDeveloperRoleId)
    principalType: 'Group'
  }
}
