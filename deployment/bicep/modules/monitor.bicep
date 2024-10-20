param location string
param naming object

param privateEndpointVnetName string
param privateEndpointSubnetName string
param hubVnetResourceId string
param appVnetResourceId string

var hubVnetName = last(split(hubVnetResourceId, '/'))
var appVnetName = last(split(appVnetResourceId, '/'))

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  location: location
  name: naming.logAnalytics
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    publicNetworkAccessForIngestion: 'Disabled'
    publicNetworkAccessForQuery: 'Enabled'
    features: {
      disableLocalAuth: true
      enableDataExport: false
    }
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  location: location
  name: naming.appInsights
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
    SamplingPercentage: 100
    WorkspaceResourceId: logAnalyticsWorkspace.id
    publicNetworkAccessForIngestion: 'Disabled'
    publicNetworkAccessForQuery: 'Enabled'
    Request_Source: 'rest'
  }
}

resource privateLinkScope 'Microsoft.Insights/privateLinkScopes@2021-07-01-preview' = {
  location: location
  name: naming.logAnalyticsPrivateLinkScope
  properties: {
    accessModeSettings: {
      ingestionAccessMode: 'PrivateOnly'
      queryAccessMode: 'Open'
    }
  }
}

resource workspaceScopedResource 'Microsoft.Insights/privateLinkScopes/scopedResources@2021-07-01-preview' = {
  parent: privateLinkScope
  name: '${logAnalyticsWorkspace.name}-connection'
  properties: {
    linkedResourceId: logAnalyticsWorkspace.id
  }
}

resource appInsightsScopedResource 'Microsoft.Insights/privateLinkScopes/scopedResources@2021-07-01-preview' = {
  parent: privateLinkScope
  name: '${appInsights.name}-connection'
  properties: {
    linkedResourceId: appInsights.id
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  location: location
  name: naming.logAnalyticsPrivateEndpoint
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', privateEndpointVnetName, privateEndpointSubnetName)
    }
    privateLinkServiceConnections: [
      {
        name: naming.logAnalyticsPrivateEndpoint
        properties: {
          privateLinkServiceId: privateLinkScope.id
          groupIds: [
            'azuremonitor'
          ]
        }
      }
    ]
  }
}

resource privateEndpointDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-01-01' = {
  parent: privateEndpoint
  name: 'PrivateLinkScopePrivateDnsZoneGroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-monitor-azure-com'
        properties: {
          privateDnsZoneId: monitorDnsZone.id
        }
      }
    ]
  }
}

resource monitorDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.monitor.azure.com'
  location: 'global'
  properties: {}
}

resource hubMonitorDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: monitorDnsZone
  name: 'link_to_${hubVnetName}'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: hubVnetResourceId
    }
  }
}

resource appMonitorDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: monitorDnsZone
  name: 'link_to_${appVnetName}'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: appVnetResourceId
    }
  }
}

output workspaceResourceId string = logAnalyticsWorkspace.id
