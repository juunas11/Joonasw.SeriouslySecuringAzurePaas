param hubVnetResourceId string
param appVnetResourceId string

var hubVnetName = last(split(hubVnetResourceId, '/'))
var appVnetName = last(split(appVnetResourceId, '/'))

resource keyVaultDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.vaultcore.azure.net'
  location: 'global'
  properties: {}
}

resource storageBlobDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.blob.${environment().suffixes.storage}'
  location: 'global'
  properties: {}
}

resource appKeyVaultDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: keyVaultDnsZone
  name: 'link_to_${appVnetName}'
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
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: hubVnetResourceId
    }
  }
}

output keyVaultDnsZoneResourceId string = keyVaultDnsZone.id
output storageBlobDnsZoneResourceId string = storageBlobDnsZone.id
