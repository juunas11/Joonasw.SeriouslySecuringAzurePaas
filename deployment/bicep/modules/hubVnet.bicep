param location string
param naming object
param addressSpace string
// param appVnetAddressSpace string
param subnets object

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
          // networkSecurityGroup: {
          //   id: ''
          // }
          // privateEndpointNetworkPolicies: 'Enabled'
        }
      }
      {
        name: subnets.firewallManagement.name
        properties: {
          addressPrefix: subnets.firewallManagement.addressPrefix
          // networkSecurityGroup: {
          //   id: ''
          // }
          // privateEndpointNetworkPolicies: 'Enabled'
        }
      }
      {
        name: subnets.monitor.name
        properties: {
          addressPrefix: subnets.monitor.addressPrefix
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          // networkSecurityGroup: {
          //   id: ''
          // }
          // privateEndpointNetworkPolicies: 'Enabled'
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
  'AzureFirewallSubnet'
)
output firewallManagementSubnetResourceId string = resourceId(
  'Microsoft.Network/virtualNetworks/subnets',
  vnet.name,
  'AzureFirewallManagementSubnet'
)
