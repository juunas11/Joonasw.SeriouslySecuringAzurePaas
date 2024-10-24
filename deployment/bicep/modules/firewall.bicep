param location string
param naming object

param firewallSubnetResourceId string
param firewallManagementSubnetResourceId string
param appGatewayPrivateIpAddress string

resource firewallPip 'Microsoft.Network/publicIPAddresses@2024-01-01' = {
  name: naming.firewallPip
  location: location
  zones: []
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource firewallManagementPip 'Microsoft.Network/publicIPAddresses@2024-01-01' = {
  name: naming.firewallManagementPip
  location: location
  zones: []
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2024-01-01' = {
  name: naming.firewallPolicy
  location: location
  properties: {
    sku: {
      tier: 'Basic'
    }
  }
}

resource dnatAppRuleCollection 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2024-01-01' = {
  parent: firewallPolicy
  name: 'dnat-app-gateway-collection'
  properties: {
    priority: 100
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyNatRuleCollection'
        priority: 100
        name: 'DNAT to App Gateway'
        action: {
          type: 'DNAT'
        }
        rules: [
          {
            ruleType: 'NatRule'
            name: 'DNAT HTTP to App Gateway'
            destinationAddresses: [
              firewallPip.properties.ipAddress
            ]
            destinationPorts: [
              '80'
            ]
            sourceAddresses: [
              '*'
            ]
            translatedAddress: appGatewayPrivateIpAddress
            translatedPort: '80'
            ipProtocols: [
              'TCP'
            ]
          }
          {
            ruleType: 'NatRule'
            name: 'DNAT HTTPS to App Gateway'
            destinationAddresses: [
              firewallPip.properties.ipAddress
            ]
            destinationPorts: [
              '443'
            ]
            sourceAddresses: [
              '*'
            ]
            translatedAddress: appGatewayPrivateIpAddress
            translatedPort: '443'
            ipProtocols: [
              'TCP'
            ]
          }
        ]
      }
    ]
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2024-01-01' = {
  name: naming.firewall
  location: location
  zones: []
  properties: {
    ipConfigurations: [
      {
        name: naming.firewallPip
        properties: {
          subnet: {
            id: firewallSubnetResourceId
          }
          publicIPAddress: {
            id: firewallPip.id
          }
        }
      }
    ]
    sku: {
      tier: 'Basic'
    }
    managementIpConfiguration: {
      name: naming.firewallManagementPip
      properties: {
        subnet: {
          id: firewallManagementSubnetResourceId
        }
        publicIPAddress: {
          id: firewallManagementPip.id
        }
      }
    }
    firewallPolicy: {
      id: firewallPolicy.id
    }
  }
}

output firewallPublicIpAddress string = firewallPip.properties.ipAddress
output firewallPrivateIpAddress string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
