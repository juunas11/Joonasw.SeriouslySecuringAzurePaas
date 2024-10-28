param location string
param naming object

param privateEndpointVnetName string
param privateEndpointSubnetName string
// param keyVaultPrivateDnsZoneId string
param managedHsmPrivateDnsZoneId string

param webAppDataProtectionKeyUri string
param webAppDataProtectionKeyName string

// HSM because why not
resource webAppDataProtectionKeyVault 'Microsoft.KeyVault/managedHSMs@2023-07-01' = {
  location: location
  name: naming.webAppDataProtectionKeyVault
  properties: {
    tenantId: tenant().tenantId
    enablePurgeProtection: true
    enableSoftDelete: true
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      defaultAction: 'Deny'
      ipRules: []
      bypass: 'None'
      virtualNetworkRules: []
    }
  }
  sku: {
    family: 'B'
    name: 'Standard_B1'
  }
}

// Only create the key once
resource webAppDataProtectionKey 'Microsoft.KeyVault/managedHSMs/keys@2023-07-01' = if (empty(webAppDataProtectionKeyUri)) {
  parent: webAppDataProtectionKeyVault
  name: webAppDataProtectionKeyName
  properties: {
    // Using P-521 curve is pretty excessive. P-384 or P256 would be faster and probably _enough_.
    curveName: 'P-521'
    kty: 'EC-HSM'
    // Could define a rotation policy here
    keyOps: [
      'wrapKey'
      'unwrapKey'
    ]
    attributes: {
      enabled: true
      exportable: false
    }
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
output webAppDataProtectionKeyUri string = empty(webAppDataProtectionKeyUri)
  ? webAppDataProtectionKey.properties.keyUri
  : webAppDataProtectionKeyUri
