param location string
param naming object

param firewallSubnetResourceId string
param firewallManagementSubnetResourceId string
param appGatewayPrivateIpAddress string
param appSubnets object
param allVnetsAddressSpace string

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

resource buildAgentRuleCollection 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2024-01-01' = {
  parent: firewallPolicy
  name: 'build-agent-outbound-collection'
  dependsOn: [
    dnatAppRuleCollection
  ]
  properties: {
    priority: 200
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        priority: 100
        name: 'Allow build agent outbound'
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'Allow build agent outbound'
            destinationAddresses: [
              '*'
            ]
            destinationPorts: [
              '80'
              '443'
              '1688' // KMS
            ]
            sourceAddresses: [
              appSubnets.buildAgent.addressPrefix
            ]
            ipProtocols: [
              'TCP'
            ]
          }
        ]
      }
    ]
  }
}

resource allowNtpRuleCollection 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2024-01-01' = {
  parent: firewallPolicy
  name: 'allow-ntp-collection'
  dependsOn: [
    buildAgentRuleCollection
  ]
  properties: {
    priority: 300
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        priority: 100
        name: 'Allow NTP'
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'Allow NTP'
            destinationAddresses: [
              '*'
            ]
            destinationPorts: [
              '123'
            ]
            sourceAddresses: [
              allVnetsAddressSpace
            ]
            ipProtocols: [
              'UDP'
            ]
          }
        ]
      }
    ]
  }
}

resource appServiceEnvironmentRuleCollection 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2024-01-01' = {
  parent: firewallPolicy
  name: 'app-service-environment-outbound-collection'
  dependsOn: [
    allowNtpRuleCollection
  ]
  properties: {
    priority: 400
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        priority: 100
        name: 'Allow App Service Environment outbound'
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'Allow App Service Environment outbound'
            sourceAddresses: [
              appSubnets.appServiceEnvironment.addressPrefix
            ]
            destinationAddresses: [
              '*'
            ]
            destinationPorts: [
              '80'
              '443'
            ]
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
  dependsOn: [
    buildAgentRuleCollection
    dnatAppRuleCollection
    allowNtpRuleCollection
    appServiceEnvironmentRuleCollection
  ]
}

output firewallPublicIpAddress string = firewallPip.properties.ipAddress
output firewallPrivateIpAddress string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
output firewallResourceId string = firewall.id
