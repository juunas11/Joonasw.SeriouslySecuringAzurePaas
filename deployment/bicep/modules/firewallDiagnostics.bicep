param firewallResourceId string
param logAnalyticsWorkspaceId string

var firewallName = last(split(firewallResourceId, '/'))

resource firewall 'Microsoft.Network/azureFirewalls@2024-01-01' existing = {
  name: firewallName
}

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: firewall
  name: 'logs-to-log-analytics'
  properties: {
    logs: [
      {
        category: 'AZFWApplicationRule'
        enabled: true
      }
      // {
      //   category: 'AZFWNatRule'
      //   enabled: true
      // }
      {
        category: 'AZFWNetworkRule'
        enabled: true
      }
    ]
    metrics: []
    workspaceId: logAnalyticsWorkspaceId
  }
}
