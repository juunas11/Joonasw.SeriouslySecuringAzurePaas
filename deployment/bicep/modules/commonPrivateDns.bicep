param appVnetResourceId string

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

resource keyVaultDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: keyVaultDnsZone
  name: 'link_to_${appVnetName}'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: appVnetResourceId
    }
  }
}

resource storageBlobDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: storageBlobDnsZone
  name: 'link_to_${appVnetName}'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: appVnetResourceId
    }
  }
}

output keyVaultDnsZoneId string = keyVaultDnsZone.id
output storageBlobDnsZoneId string = storageBlobDnsZone.id
