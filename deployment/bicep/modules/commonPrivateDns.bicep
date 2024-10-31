param hubVnetResourceId string
param appVnetResourceId string

var hubVnetName = last(split(hubVnetResourceId, '/'))
var appVnetName = last(split(appVnetResourceId, '/'))

// resource keyVaultDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
//   name: 'privatelink.vaultcore.azure.net'
//   location: 'global'
//   properties: {}
// }

resource managedHsmDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.managedhsm.azure.net'
  location: 'global'
  properties: {}
}

resource storageBlobDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.blob.${environment().suffixes.storage}'
  location: 'global'
  properties: {}
}

resource appServiceEnvironmentDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'appserviceenvironment.net'
  location: 'global'
}

// resource azureSqlDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
//   #disable-next-line no-hardcoded-env-urls
//   name: 'privatelink.database.windows.net'
//   location: 'global'
// }

// resource appServiceDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
//   name: 'privatelink.azurewebsites.net'
//   location: 'global'
// }

// resource appKeyVaultDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
//   parent: keyVaultDnsZone
//   name: 'link_to_${appVnetName}'
//   location: 'global'
//   properties: {
//     registrationEnabled: false
//     virtualNetwork: {
//       id: appVnetResourceId
//     }
//   }
// }

resource appManagedHsmDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: managedHsmDnsZone
  name: 'link_to_${appVnetName}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: appVnetResourceId
    }
  }
}

resource appStorageBlobDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: storageBlobDnsZone
  name: 'link_to_${appVnetName}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: appVnetResourceId
    }
  }
}

resource hubStorageBlobDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: storageBlobDnsZone
  name: 'link_to_${hubVnetName}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: hubVnetResourceId
    }
  }
}

resource appAppServiceEnvironmentDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: appServiceEnvironmentDnsZone
  name: 'link_to_${appVnetName}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: appVnetResourceId
    }
  }
}

// resource appAppServiceDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
//   parent: appServiceDnsZone
//   name: 'link_to_${appVnetName}'
//   location: 'global'
//   properties: {
//     registrationEnabled: false
//     virtualNetwork: {
//       id: appVnetResourceId
//     }
//   }
// }

// output keyVaultDnsZoneResourceId string = keyVaultDnsZone.id
output managedHsmDnsZoneResourceId string = managedHsmDnsZone.id
output storageBlobDnsZoneResourceId string = storageBlobDnsZone.id
output appServiceEnvironmentDnsZoneResourceId string = appServiceEnvironmentDnsZone.id
// output appServiceDnsZoneResourceId string = appServiceDnsZone.id
