param location string
param naming object
param addressSpace string
param allVnetsAddressSpace string
// param appVnetAddressSpace string
param subnets object

var denyAllInboundRule = {
  name: 'DenyAllInbound'
  properties: {
    priority: 4096
    direction: 'Inbound'
    access: 'Deny'
    protocol: '*'
    sourceAddressPrefix: '*'
    sourcePortRange: '*'
    destinationAddressPrefix: '*'
    destinationPortRange: '*'
  }
}
var denyAllOutboundRule = {
  name: 'DenyAllOutbound'
  properties: {
    priority: 4096
    direction: 'Outbound'
    access: 'Deny'
    protocol: '*'
    sourceAddressPrefix: '*'
    sourcePortRange: '*'
    destinationAddressPrefix: '*'
    destinationPortRange: '*'
  }
}

resource monitorNsg 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: 'nsg-hub-${subnets.monitor.name}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowHttpInboundFromVnet'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: allVnetsAddressSpace
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '80'
        }
      }
      {
        name: 'AllowHttpsInboundFromVnet'
        properties: {
          priority: 200
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: allVnetsAddressSpace
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      denyAllInboundRule
      denyAllOutboundRule
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: naming.hubVnet
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressSpace
      ]
    }
    subnets: [
      {
        name: subnets.firewall.name
        properties: {
          addressPrefix: subnets.firewall.addressPrefix
        }
      }
      {
        name: subnets.firewallManagement.name
        properties: {
          addressPrefix: subnets.firewallManagement.addressPrefix
        }
      }
      {
        name: subnets.monitor.name
        properties: {
          addressPrefix: subnets.monitor.addressPrefix
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          // TODO: Re-enable
          // networkSecurityGroup: {
          //   id: monitorNsg.id
          // }
        }
      }
    ]
    // enableDdosProtection: true
    // ddosProtectionPlan: {
    //   id: ''
    // }
  }
}

output vnetResourceId string = vnet.id
output firewallSubnetResourceId string = resourceId(
  'Microsoft.Network/virtualNetworks/subnets',
  vnet.name,
  subnets.firewall.name
)
output firewallManagementSubnetResourceId string = resourceId(
  'Microsoft.Network/virtualNetworks/subnets',
  vnet.name,
  subnets.firewallManagement.name
)
