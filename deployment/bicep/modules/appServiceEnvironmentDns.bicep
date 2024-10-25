param location string
param appServiceEnvironmentDnsSuffix string
param appServiceEnvironmentIpAddress string

resource dnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  location: location
  name: appServiceEnvironmentDnsSuffix
}

resource wildcardRecord 'Microsoft.Network/privateDnsZones/A@2024-06-01' = {
  parent: dnsZone
  name: '*'
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: appServiceEnvironmentIpAddress
      }
    ]
  }
}
