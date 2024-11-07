param nsgResourceId string
param logAnalyticsWorkspaceId string

var nsgName = last(split(nsgResourceId, '/'))

resource nsg 'Microsoft.Network/networkSecurityGroups@2024-01-01' existing = {
  name: nsgName
}

resource nsgDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'nsg-logs-to-loganalytics'
  scope: nsg
  properties: {
    logs: [
      {
        category: 'NetworkSecurityGroupEvent'
        enabled: true
      }
      {
        category: 'NetworkSecurityGroupRuleCounter'
        enabled: true
      }
    ]
    metrics: []
    workspaceId: logAnalyticsWorkspaceId
  }
}
