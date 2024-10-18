param location string
param naming object
param vnetAddressSpaces object

resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: naming.hubVnet
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [vnetAddressSpaces.hub]
    }
    subnets: [
      {
        name: ''
        properties: {
          addressPrefix: ''
          networkSecurityGroup: {
            id: ''
          }
          privateEndpointNetworkPolicies: 'Enabled'
        }
      }
    ]
    // enableDdosProtection: true
    // ddosProtectionPlan: {
    //   id: ''
    // }
  }
}
