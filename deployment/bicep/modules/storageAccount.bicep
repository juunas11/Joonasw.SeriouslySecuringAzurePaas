param location string
param naming object

param privateEndpointVnetName string
param privateEndpointSubnetName string
param storageBlobPrivateDnsZoneId string

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  location: location
  name: naming.storageAccount
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    defaultToOAuthAuthentication: true
    // encryption: {

    // }
    minimumTlsVersion: 'TLS1_2'
    publicNetworkAccess: 'Disabled'
    supportsHttpsTrafficOnly: true
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobService
  name: naming.storageWebAppAuthenticationContainer
  properties: {
    publicAccess: 'None'
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-01-01' = {
  name: naming.storageAccountPrivateEndpoint
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', privateEndpointVnetName, privateEndpointSubnetName)
    }
    privateLinkServiceConnections: [
      {
        name: '${naming.storageAccount}-connection'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

resource privateEndpointDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-01-01' = {
  parent: privateEndpoint
  name: 'PrivateEndpointPrivateDnsZoneGroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-blob-core-windows-net'
        properties: {
          privateDnsZoneId: storageBlobPrivateDnsZoneId
        }
      }
    ]
  }
}

output storageAccountResourceId string = storageAccount.id
