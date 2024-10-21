param location string
param naming object

param privateEndpointVnetName string
param privateEndpointSubnetName string
param keyVaultPrivateDnsZoneId string

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  location: location
  name: naming.keyVault
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant().tenantId
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    enablePurgeProtection: true
    enableSoftDelete: true
    enableRbacAuthorization: true
    publicNetworkAccess: 'Disabled'
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-01-01' = {
  name: naming.keyVaultPrivateEndpoint
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', privateEndpointVnetName, privateEndpointSubnetName)
    }
    privateLinkServiceConnections: [
      {
        name: '${naming.keyVault}-connection'
        properties: {
          privateLinkServiceId: keyVault.id
          groupIds: [
            'vault'
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
        name: 'privatelink-vault-azure-com'
        properties: {
          privateDnsZoneId: keyVaultPrivateDnsZoneId
        }
      }
    ]
  }
}

output keyVaultResourceId string = keyVault.id
