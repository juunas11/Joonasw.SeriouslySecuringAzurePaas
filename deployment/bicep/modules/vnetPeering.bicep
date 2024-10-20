param hubVnetName string
param spokeVnetName string

resource hubVnet 'Microsoft.Network/virtualNetworks@2024-01-01' existing = {
  name: hubVnetName
}

resource spokeVnet 'Microsoft.Network/virtualNetworks@2024-01-01' existing = {
  name: spokeVnetName
}

resource spokeToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-01-01' = {
  parent: spokeVnet
  name: '${spokeVnetName}-to-${hubVnetName}'
  properties: {
    allowForwardedTraffic: false
    allowGatewayTransit: false
    allowVirtualNetworkAccess: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: hubVnet.id
    }
  }
}

resource hubToSpokePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-01-01' = {
  parent: hubVnet
  name: '${hubVnetName}-to-${spokeVnetName}'
  dependsOn: [
    // Add this peering after the spoke-to-hub peering is created
    spokeToHubPeering
  ]
  properties: {
    allowForwardedTraffic: false
    allowGatewayTransit: false
    allowVirtualNetworkAccess: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: spokeVnet.id
    }
  }
}
