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
    natRuleCollections: [
      {
        name: ''
        properties: {
          rules: [
            {
              name: 'DNAT to App Gateway'
              description: 'Guides traffic to Firewall Public IP to App Gateway'
              destinationAddresses: [
                firewallPip.properties.ipAddress
              ]
              destinationPorts: [
                '80'
                '443'
              ]
              translatedAddress: appGatewayPrivateIpAddress
              protocols: [
                'TCP'
              ]
            }
          ]
        }
      }
    ]
  }
}

output firewallPublicIpAddress string = firewallPip.properties.ipAddress
output firewallPrivateIpAddress string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
