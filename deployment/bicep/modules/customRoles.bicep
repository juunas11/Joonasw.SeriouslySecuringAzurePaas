param limitedDeveloperUserObjectId string

resource developerProductionRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: guid('SSAP Developer - Production')
  properties: {
    roleName: 'SSAP Developer - Production'
    description: 'Can read and restart App Services, and open support tickets'
    type: 'CustomRole'
    permissions: [
      {
        actions: [
          // Read and restart App Services
          'Microsoft.Web/sites/read'
          'Microsoft.Web/sites/restart/action'
          'Microsoft.Web/sites/slots/read'
          'Microsoft.Web/sites/slots/restart/action'
          'Microsoft.Web/serverfarms/read'
          // Open support tickets
          'Microsoft.Support/*'
        ]
        notActions: []
        dataActions: []
        notDataActions: []
      }
    ]
    assignableScopes: [
      '/subscriptions/${subscription().subscriptionId}'
    ]
  }
}

resource developerProductionRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(limitedDeveloperUserObjectId, developerProductionRole.name)
  scope: resourceGroup()
  properties: {
    principalId: limitedDeveloperUserObjectId
    roleDefinitionId: developerProductionRole.id
    principalType: 'User'
  }
}
