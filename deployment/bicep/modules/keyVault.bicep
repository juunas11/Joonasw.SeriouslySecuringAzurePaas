param location string
param naming object

param privateEndpointVnetName string
param privateEndpointSubnetName string
// param keyVaultPrivateDnsZoneId string
param managedHsmPrivateDnsZoneId string

// param webAppDataProtectionKeyUri string
// param webAppDataProtectionKeyName string
param initialKeyVaultAdminObjectId string

// HSM because why not
resource webAppDataProtectionKeyVault 'Microsoft.KeyVault/managedHSMs@2023-07-01' = {
  location: location
  name: naming.webAppDataProtectionKeyVault
  properties: {
    tenantId: tenant().tenantId
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      defaultAction: 'Deny'
      ipRules: []
      bypass: 'None'
      virtualNetworkRules: []
    }
    initialAdminObjectIds: [
      initialKeyVaultAdminObjectId
    ]
    enableSoftDelete: true
    // You would normally want this two enabled.
    // However, I redeploy these resources all the time,
    // and I would like to be able to delete them.
    enablePurgeProtection: false
  }
  sku: {
    family: 'B'
    name: 'Standard_B1'
  }
}

// resource webAppDataProtectionKeyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
//   location: location
//   name: naming.webAppDataProtectionKeyVault
//   properties: {
//     sku: {
//       family: 'A'
//       name: 'standard'
//     }
//     tenantId: tenant().tenantId
//     enabledForDeployment: false
//     enabledForDiskEncryption: false
//     enabledForTemplateDeployment: false
//     enablePurgeProtection: true
//     enableSoftDelete: true
//     enableRbacAuthorization: true
//     publicNetworkAccess: 'Disabled'
//   }
// }

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-01-01' = {
  name: naming.keyVaultPrivateEndpoint
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', privateEndpointVnetName, privateEndpointSubnetName)
    }
    privateLinkServiceConnections: [
      {
        name: '${naming.webAppDataProtectionKeyVault}-connection'
        properties: {
          privateLinkServiceId: webAppDataProtectionKeyVault.id
          groupIds: [
            // 'vault'
            'managedhsm'
          ]
        }
      }
    ]
  }
}

// resource privateEndpointDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-01-01' = {
//   parent: privateEndpoint
//   name: 'PrivateEndpointPrivateDnsZoneGroup'
//   properties: {
//     privateDnsZoneConfigs: [
//       {
//         name: 'privatelink-vault-azure-com'
//         properties: {
//           privateDnsZoneId: keyVaultPrivateDnsZoneId
//         }
//       }
//     ]
//   }
// }

resource privateEndpointDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-01-01' = {
  parent: privateEndpoint
  name: 'PrivateEndpointPrivateDnsZoneGroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-managedhsm-azure-net'
        properties: {
          privateDnsZoneId: managedHsmPrivateDnsZoneId
        }
      }
    ]
  }
}

output webAppDataProtectionKeyVaultResourceId string = webAppDataProtectionKeyVault.id
output webAppDataProtectionKeyVaultName string = webAppDataProtectionKeyVault.name
// output webAppDataProtectionKeyUri string = empty(webAppDataProtectionKeyUri)
//   ? webAppDataProtectionKey.properties.keyUri
//   : webAppDataProtectionKeyUri
