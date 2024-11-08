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
          // Read and restart App Services, look at metrics
          'Microsoft.Web/sites/read'
          'Microsoft.Web/sites/config/Read'
          'Microsoft.Web/sites/restart/action'
          'Microsoft.Insights/metrics/read'
          'Microsoft.Web/sites/metrics/read'
          'Microsoft.Web/sites/providers/Microsoft.Insights/metricDefinitions/Read'
          'Microsoft.Web/sites/usages/read'
          'Microsoft.Web/serverfarms/read'
          'Microsoft.Web/serverfarms/usages/read'
          'Microsoft.Web/serverfarms/metrics/read'
          'Microsoft.Web/serverfarms/providers/Microsoft.Insights/metricDefinitions/Read'
          'Microsoft.Web/hostingEnvironments/Read'
          // Open support tickets
          'Microsoft.Support/*'
        ]
        notActions: []
        dataActions: []
        notDataActions: []
      }
    ]
    assignableScopes: [
      '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}'
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
