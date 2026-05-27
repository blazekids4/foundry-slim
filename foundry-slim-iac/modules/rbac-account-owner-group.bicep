// Assigns Azure AI Administrator on the Foundry account for the Account Owner group.
// No connected-service roles — this is a Foundry-only deployment.

@description('Object ID of the Entra ID group for Account Owners')
param accountOwnerGroupObjectId string

@description('Name of the AI Foundry account')
param foundryAccountName string

var azureAiAdministratorRoleId = 'b78c5d69-af96-48a3-bf8d-a8b4d589de94'

resource foundryAccount 'Microsoft.CognitiveServices/accounts@2025-06-01' existing = {
  name: foundryAccountName
}

resource ownerGroupFoundryAccountRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: foundryAccount
  name: guid(accountOwnerGroupObjectId, azureAiAdministratorRoleId, foundryAccount.id)
  properties: {
    principalId: accountOwnerGroupObjectId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', azureAiAdministratorRoleId)
    principalType: 'Group'
  }
}
