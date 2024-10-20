param location string
param naming object

param addressSpace string
param subnets object

resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: naming.appVnet
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressSpace
      ]
    }
    subnets: [
      {
        name: subnets.appServiceEnvironment.name
        properties: {
          addressPrefix: subnets.appServiceEnvironment.addressPrefix
          delegations: [
            {
              name: 'Microsoft.Web/hostingEnvironments'
              properties: {
                serviceName: 'Microsoft.Web/hostingEnvironments'
              }
            }
          ]
        }
      }
      {
        name: subnets.appGateway.name
        properties: {
          addressPrefix: subnets.appGateway.addressPrefix
        }
      }
      {
        name: subnets.sql.name
        properties: {
          addressPrefix: subnets.sql.addressPrefix
        }
      }
      {
        name: subnets.appServiceKeyVault.name
        properties: {
          addressPrefix: subnets.appServiceKeyVault.addressPrefix
        }
      }
      {
        name: subnets.storage.name
        properties: {
          addressPrefix: subnets.storage.addressPrefix
        }
      }
      {
        name: subnets.sqlKeyVault.name
        properties: {
          addressPrefix: subnets.sqlKeyVault.addressPrefix
        }
      }
      {
        name: subnets.storageKeyVault.name
        properties: {
          addressPrefix: subnets.storageKeyVault.addressPrefix
        }
      }
    ]
  }
}
