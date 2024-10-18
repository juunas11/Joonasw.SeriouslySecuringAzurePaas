param location string
param naming object
param vnetAddressSpaces object

resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: naming.appVnet
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressSpaces.app
      ]
    }
    subnets: [
      {
        name: naming.appSubnet
        properties: {
          addressPrefix: vnetAddressSpaces.appSubnet
          delegations: [
            {
              name: ''
              properties: {
                serviceName: 'Microsoft.Web/hostingEnvironments'
              }
            }
          ]
        }
      }
    ]
  }
}
