param location string
param naming object

param privateEndpointVnetName string
param privateEndpointSubnetName string
param managedHsmPrivateDnsZoneId string
param initialAdminObjectId string

// HSM because why not
resource webAppDataProtectionManagedHsm 'Microsoft.KeyVault/managedHSMs@2023-07-01' = {
  location: location
  name: naming.webAppDataProtectionManagedHsm
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
      initialAdminObjectId
    ]
    enableSoftDelete: true
    // You would normally want this two enabled.
    // However, I redeploy these resources all the time,
    // and I would like to be able to delete them to save costs.
    enablePurgeProtection: false
  }
  sku: {
    family: 'B'
    name: 'Standard_B1'
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-01-01' = {
  name: naming.managedHsmPrivateEndpoint
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', privateEndpointVnetName, privateEndpointSubnetName)
    }
    privateLinkServiceConnections: [
      {
        name: '${webAppDataProtectionManagedHsm.name}-connection'
        properties: {
          privateLinkServiceId: webAppDataProtectionManagedHsm.id
          groupIds: [
            'managedhsm'
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
        name: 'privatelink-managedhsm-azure-net'
        properties: {
          privateDnsZoneId: managedHsmPrivateDnsZoneId
        }
      }
    ]
  }
}

output webAppDataProtectionManagedHsmResourceId string = webAppDataProtectionManagedHsm.id
output webAppDataProtectionManagedHsmName string = webAppDataProtectionManagedHsm.name
