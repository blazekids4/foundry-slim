// Assigns the Contributor role at subscription scope for the admin Entra ID group.

targetScope = 'subscription'

@description('Object ID of the Entra ID group for subscription admins')
param subscriptionAdminGroupObjectId string

var contributorRoleId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

resource subscriptionAdminRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscriptionAdminGroupObjectId, contributorRoleId, subscription().id)
  properties: {
    principalId: subscriptionAdminGroupObjectId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', contributorRoleId)
    principalType: 'Group'
  }
}
